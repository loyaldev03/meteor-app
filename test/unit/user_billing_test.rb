require 'test_helper'

class UserBillingTest < ActiveSupport::TestCase
  setup do
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @sd_strategy          = FactoryBot.create(:soft_decline_strategy, response_code: '522', gateway: 'payeezy')
    @hd_strategy          = FactoryBot.create(:hard_decline_strategy, response_code: '502', gateway: 'payeezy')
    active_merchant_stubs_payeezy
  end

  test 'Bill membership if it is active or provisional' do
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    prev_bill_date      = user.next_retry_bill_date
    installment_period  = @terms_of_membership.installment_period.days

    # billing provisional user
    Timecop.travel(user.next_retry_bill_date) do
      answer = user.bill_membership
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal user.status, 'active'
      assert_equal user.recycled_times, 0, "recycled_times is #{user.recycled_times} should be 0"
      assert_equal user.bill_date, user.next_retry_bill_date, "bill_date is #{user.bill_date} should be #{user.next_retry_bill_date}"
      assert_equal user.next_retry_bill_date.to_date, (Time.zone.now + installment_period).to_date
      assert_equal I18n.l(user.next_retry_bill_date, format: :only_date), I18n.l((prev_bill_date + user.terms_of_membership.installment_period.days), format: :only_date), "next_retry_bill_date is #{user.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
    # billing active user
    prev_bill_date = user.next_retry_bill_date
    Timecop.travel(user.next_retry_bill_date) do
      answer = user.bill_membership
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal user.status, 'active'
      assert_equal user.recycled_times, 0, "recycled_times is #{user.recycled_times} should be 0"
      assert_equal user.bill_date, user.next_retry_bill_date, "bill_date is #{user.bill_date} should be #{user.next_retry_bill_date}"
      assert_equal I18n.l(user.next_retry_bill_date, format: :only_date), I18n.l((prev_bill_date + user.terms_of_membership.installment_period.days), format: :only_date), "next_retry_bill_date is #{user.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  test 'Bill membership if it user has cc_blank amount = zero' do
    @tom_without_provisional  = FactoryBot.create(:terms_of_membership_monthly_without_provisional_day_and_amount, club_id: @club.id)
    user                      = enroll_user(FactoryBot.build(:user), @tom_without_provisional, 0, true)

    assert_difference('Operation.count', 4) do
      assert_difference('Transaction.count', 1) do
        user.bill_membership
      end
    end
    assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.membership_billing, token: 'a', amount: 0.0)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.membership_bill_email)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.add_club_cash)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.renewal_scheduled)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.membership_billing)
    assert_equal user.status, 'active'
  end

  test 'Do not bill users with blank credit cards' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true)
    Timecop.travel(user.next_retry_bill_date) do
      answer = user.bill_membership
      assert_equal answer[:message], 'Credit card is blank we wont bill'
      assert_equal answer[:code], '9997'
    end
  end

  test 'Monthly user billed 24 months' do
    user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    nbd         = user.next_retry_bill_date
    club_cash   = user.club_cash_amount
    1.upto(24) do
      Timecop.travel(user.next_retry_bill_date) do
        user.bill_membership
        nbd += user.reload.terms_of_membership.installment_period.days
        assert_equal I18n.l(nbd, format: :only_date), I18n.l(user.next_retry_bill_date, format: :only_date)
        assert_equal user.bill_date, user.next_retry_bill_date
        assert_equal user.recycled_times, 0
        assert_equal user.club_cash_amount, club_cash + @terms_of_membership.club_cash_installment_amount
        club_cash = user.club_cash_amount
      end
    end
  end

  test 'Yearly user billed 4 years' do
    @terms_of_membership_with_gateway_yearly = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    user                                     = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway_yearly)
    nbd                                      = user.bill_date
    2.upto(5) do |_time|
      Timecop.travel(user.next_retry_bill_date) do
        user.bill_membership
        nbd += user.reload.terms_of_membership.installment_period.days
        assert_equal I18n.l(nbd, format: :only_date), I18n.l(user.next_retry_bill_date, format: :only_date)
        assert_equal user.bill_date, user.next_retry_bill_date
        assert_equal user.recycled_times, 0
      end
    end
  end

  test 'Recycle credit card with billing success' do
    user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_year = (Time.zone.now - 2.years).year
    user.credit_cards.each { |s| s.update_attribute :expire_year, original_year } # force to be expired!
    user.reload

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('CreditCard.count', 0) do
        assert_difference('Operation.count', 5) do  # club cash, renewal, recycle, bill, set as active, membership_bill communication
          assert_difference('Transaction.count') do
            assert_equal user.recycled_times, 0
            answer = user.bill_membership
            assert_equal answer[:code], Settings.error_codes.success
            assert_equal original_year + 3, user.transactions.last.expire_year
            assert_equal user.recycled_times, 0
            assert_equal user.credit_cards.count, 1 # only one credit card
            assert_equal user.active_credit_card.expire_year, original_year + 3 # expire_year should be +3 years.
          end
        end
      end
    end
  end

  test 'Do not bill membership before next retry bill date' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    (Time.current.to_date..(user.next_retry_bill_date - 1.day).to_date).each do |date|
      Timecop.travel(date) do
        answer = user.bill_membership
        assert_equal answer[:message], "We haven't reach next bill date yet."
        assert_equal answer[:code], Settings.error_codes.billing_date_not_reached
      end
    end
  end

  test 'Do not bill users within club with billing_enable set as false' do
    @club.update_attribute(:billing_enable, false)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    next_bill_date_before = user.next_retry_bill_date
    bill_date_before      = user.bill_date

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Operation.count', 0) do
        assert_difference('Transaction.count', 0) do
          answer = user.bill_membership
          assert_equal answer[:code], Settings.error_codes.user_club_dont_allow
          assert_equal answer[:message], "User's club is not allowing billing"
          assert_equal next_bill_date_before.to_s, user.next_retry_bill_date.to_s
          assert_equal bill_date_before.to_s, user.bill_date.to_s
        end
      end
    end
  end

  test 'Do not bill users when terms of membership is not expecting billing.' do
    @terms_of_membership.update_attribute(:is_payment_expected, false)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    next_bill_date_before = user.next_retry_bill_date
    bill_date_before      = user.bill_date

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Operation.count', 0) do
        assert_difference('Transaction.count', 0) do
          answer = user.bill_membership
          assert_equal answer[:code], Settings.error_codes.user_not_expecting_billing
          assert_equal answer[:message], 'User is not expected to get billed.'
          assert_equal next_bill_date_before.to_s, user.next_retry_bill_date.to_s
          assert_equal bill_date_before.to_s, user.bill_date.to_s
        end
      end
    end
  end

  test 'Make no recurrent billing with user not expecting billing' do
    @terms_of_membership.update_attribute(:is_payment_expected, false)
    %w[donation one-time].each do |no_recurrent_type|
      user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, false)
      amount = 200
      assert_difference('Transaction.count', 1) do
        assert_difference('Operation.count') do
          user.no_recurrent_billing(amount, 'testing event', no_recurrent_type)
          assert user.provisional?
          assert_nil user.bill_date
          assert_nil user.next_retry_bill_date
          operation_type = no_recurrent_type == 'donation' ? Settings.operation_types.no_reccurent_billing_donation : Settings.operation_types.no_recurrent_billing
          assert_not_nil user.reload.transactions.find_by(operation_type: operation_type)
        end
      end
    end
  end

  test 'Do not bill lapsed users' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.set_as_canceled!
    answer = user.bill_membership
    assert answer[:code] == Settings.error_codes.user_status_dont_allow
    assert answer[:message] == 'User is not in a billing status.'
  end

  test 'Do not bill if no credit card is on file' do
    user    = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true)
    answer  = user.bill_membership
    assert (answer[:code] != Settings.error_codes.success), answer[:message]
  end

  test 'Add club cash upon membership billings' do
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway,
                                             club_id: @club.id,
                                             club_cash_installment_amount: 100,
                                             skip_first_club_cash: false)
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0)
    original_club_cash = user.club_cash_amount

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count') do
        assert_difference('ClubCashTransaction.count') do
          user.bill_membership
        end
      end
      assert_equal user.reload.club_cash_amount, original_club_cash + @terms_of_membership.club_cash_installment_amount
    end
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count') do
        assert_difference('ClubCashTransaction.count') do
          user.bill_membership
        end
      end
      assert_equal user.reload.club_cash_amount, original_club_cash + (@terms_of_membership.club_cash_installment_amount * 2)
    end
  end

  test 'Do not Add club cash on first membership billing if skip_first_club_cash is false' do
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway,
                                             club_id: @club.id,
                                             club_cash_installment_amount: 100,
                                             skip_first_club_cash: true)
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0)
    original_club_cash = user.club_cash_amount

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count') do
        assert_difference('ClubCashTransaction.count', 0) do
          user.bill_membership
        end
      end
      assert_equal user.reload.club_cash_amount, original_club_cash
    end

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count') do
        assert_difference('ClubCashTransaction.count') do
          user.bill_membership
        end
      end
      assert_equal user.reload.club_cash_amount, original_club_cash + @terms_of_membership.club_cash_installment_amount
    end
  end

  test 'User is upgraded upon reaching upgrade period when billing membership' do
    @tom_with_upgrade = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id,
                                                                             upgrade_tom_id: @terms_of_membership.id,
                                                                             upgrade_tom_period: 65,
                                                                             provisional_days: 30,
                                                                             installment_period: 30)
    user = enroll_user(FactoryBot.build(:user), @tom_with_upgrade)
    # first and second billing, it should not upgrade
    2.times do
      Timecop.travel(user.next_retry_bill_date) do
        user.bill_membership
        user.reload
        assert_equal user.current_membership.terms_of_membership_id, @tom_with_upgrade.id
      end
    end
    # Third billing, it should upgrade
    Timecop.travel(user.next_retry_bill_date) do
      user.bill_membership
      assert_equal user.reload.current_membership.terms_of_membership_id, @terms_of_membership.id
      assert_not_nil user.operations.where(operation_type: Settings.operation_types.tom_upgrade).first
    end
  end

  test 'User with manual payment is upgraded upon reaching upgrade period when billing membership' do
    @tom_with_upgrade = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id,
                                                                             upgrade_tom_id: @terms_of_membership.id,
                                                                             upgrade_tom_period: 65,
                                                                             provisional_days: 30,
                                                                             installment_period: 30)
    user = enroll_user(FactoryBot.build(:user), @tom_with_upgrade)
    user.update_attribute :manual_payment, true

    # first and second billing, it should not upgrade
    2.times do
      Timecop.travel(user.next_retry_bill_date) do
        assert_difference('Membership.count', 0) do
          user.manual_billing(@tom_with_upgrade.installment_amount, 'cash')
          assert_equal user.reload.current_membership.terms_of_membership_id, @tom_with_upgrade.id
        end
      end
    end
    # Third billing, it should upgrade
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Membership.count') do
        user.manual_billing(@tom_with_upgrade.installment_amount, 'cash')
      end
      assert_equal user.reload.current_membership.terms_of_membership_id, @terms_of_membership.id
      assert_not_nil user.operations.where(operation_type: Settings.operation_types.tom_upgrade).first
    end
  end

  test 'Billing declined, but there is no decline rule. Send email' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    active_merchant_stubs_payeezy('34234', 'decline stubbed', false)
    Timecop.travel(user.next_retry_bill_date) do
      user.bill_membership
      assert_equal user.reload.next_retry_bill_date.to_date, (Time.zone.now + eval(Settings.next_retry_on_missing_decline)).to_date
    end
    transaction = user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy, transaction_type: 'sale')
    assert_equal user.operations.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy).description, "Billing error. No decline rule configured: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}"
  end

  test 'Billing declined, but there is no decline rule and limit is reached. Send email' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.update_attribute :recycled_times, 5
    active_merchant_stubs_payeezy('34234', 'decline stubbed', false)
    assert_difference('Operation.count', 6) do
      Timecop.travel(user.next_retry_bill_date) do
        user.bill_membership
      end
    end
    transaction = user.reload.transactions.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy_max_retries, transaction_type: 'sale')
    assert_equal Operation.find_by_user_id_and_operation_type(user.id, Settings.operation_types.membership_billing_without_decline_strategy_max_retries).description, "Billing error. No decline rule configured limit reached: #{transaction.response_code} #{transaction.gateway}: #{transaction.response_result}"
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy_max_retries)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.future_cancel)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.cancellation_email)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.cancel)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.deducted_club_cash)
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.hard_decline_email)
  end

  test 'User gets soft decline upon billing membership' do
    user            = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    bill_date       = user.bill_date
    active_merchant_stubs_payeezy(@sd_strategy.response_code, 'decline stubbed', false)

    Timecop.travel(user.next_retry_bill_date) do
      user.bill_membership
      assert user.reload.provisional?
      assert_equal bill_date, user.bill_date
      assert_equal user.next_retry_bill_date.to_date, (Time.current + @sd_strategy.days.days).to_date
      assert_equal user.recycled_times, 1
      assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.membership_billing_soft_decline)
      assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.soft_decline_email)
    end
  end

  test 'User gets canceled upon getting Hard Decline when billing membership' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    active_merchant_stubs_payeezy(@hd_strategy.response_code, 'decline stubbed', false)
    assert_difference('Operation.count', 6) do
      assert_difference('Communication.count', 2) do
        assert_difference('Transaction.count', 1) do
          Timecop.travel(user.next_retry_bill_date) do
            user.bill_membership
            assert user.reload.lapsed?
            assert_nil user.next_retry_bill_date
            assert_nil user.bill_date
            assert_not_nil user.cancel_date
            assert_equal user.recycled_times, 0
            assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_hard_decline, transaction_type: 'sale')
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.cancel)
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.deducted_club_cash)
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.hard_decline_email)
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.cancellation_email)
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.future_cancel)
            assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.membership_billing_hard_decline)
          end
        end
      end
    end
  end

  test 'User gets downgraded upon getting Hard Decline when billing membership' do
    @terms_of_membership_for_downgrade    = FactoryBot.create(:terms_of_membership_for_downgrade, club_id: @club.id)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill   = 'downgrade_tom'
    @terms_of_membership.save
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_membership = user.current_membership
    active_merchant_stubs_payeezy(@hd_strategy.response_code, 'decline stubbed', false)
    assert_difference('Operation.count', 4) do
      assert_difference('Transaction.count', 1) do
        Timecop.travel(user.next_retry_bill_date) do
          active_merchant_stubs_payeezy(@hd_strategy.response_code, 'decline stubbed', false)
          user.bill_membership
          user.reload.provisional?
          assert_equal user.recycled_times, 0
          assert_equal user.terms_of_membership.id, @terms_of_membership_for_downgrade.id
          assert_equal user.current_membership.parent_membership_id, original_membership.id
          assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.downgraded_because_of_hard_decline, transaction_type: 'sale')
          assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.downgrade_user, resource_id: @terms_of_membership_for_downgrade.id)
          assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.enrollment_billing, resource_id: @terms_of_membership_for_downgrade.id)
          assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.enrollment, resource_id: user.current_membership_id)
          assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.downgraded_because_of_hard_decline)
        end
      end
    end
  end

  test 'User gets Soft Decline several times until gets Hard Decline and canceled' do
    user            = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    next_bill_date  = user.next_retry_bill_date
    bill_date       = user.bill_date
    active_merchant_stubs_payeezy(@sd_strategy.response_code, 'decline stubbed', false)

    1.upto(15) do |time|
      Timecop.travel(user.next_retry_bill_date) do
        user.bill_membership
        next if user.reload.lapsed?

        # user is rescheduled for billing
        next_bill_date += @sd_strategy.days.days
        assert_equal next_bill_date.to_date, user.next_retry_bill_date.to_date
        assert_equal bill_date, user.bill_date
        assert_not_equal user.bill_date, user.next_retry_bill_date
        # increases recycled times
        assert_equal time, user.recycled_times
        # Operation Soft Decline created
        assert_equal time, user.operations.where(operation_type: Settings.operation_types.membership_billing_soft_decline).count
      end
    end
    assert_nil user.next_retry_bill_date
    assert_nil user.bill_date
    assert_not_nil user.cancel_date
    assert_equal 0, user.recycled_times
    assert_equal 1, user.operations.where(operation_type: Settings.operation_types.membership_billing_hard_decline_by_max_retries).count
  end

  test 'User gets Soft Decline several times until gets Hard Decline and downgraded' do
    @terms_of_membership_for_downgrade    = FactoryBot.create(:terms_of_membership_for_downgrade, club_id: @club.id)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill   = 'downgrade_tom'
    @terms_of_membership.save

    user                = enroll_user(FactoryBot.build(:user, email: 'sebastian@test.com'), @terms_of_membership)
    next_bill_date      = user.next_retry_bill_date
    bill_date           = user.bill_date
    original_membership = user.current_membership

    1.upto(15) do |time|
      Timecop.travel(next_bill_date) do
        active_merchant_stubs_payeezy(@sd_strategy.response_code, 'decline stubbed', false)
        user.bill_membership
        next if @terms_of_membership_for_downgrade.id == user.reload.terms_of_membership.id

        # user is rescheduled for billing
        next_bill_date += @sd_strategy.days.days
        assert_equal next_bill_date.to_date, user.next_retry_bill_date.to_date
        assert_equal bill_date, user.bill_date
        assert_not_equal user.bill_date, user.next_retry_bill_date
        # increases recycled times
        assert_equal time, user.recycled_times
        # Operation Soft Decline created
        assert_equal time, user.operations.where(operation_type: Settings.operation_types.membership_billing_soft_decline).count
      end
    end

    assert_nil user.cancel_date
    assert_not_nil user.bill_date
    assert_not_nil user.next_retry_bill_date
    assert_equal 0, user.recycled_times
    assert_equal 1, user.operations.where(operation_type: Settings.operation_types.downgraded_because_of_hard_decline_by_max_retries).count
    assert_equal user.current_membership.parent_membership_id, original_membership.id
  end

  test 'Chargeback transaction' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    Timecop.travel(user.next_retry_bill_date) { user.bill_membership }
    assert user.reload.active?

    transaction = user.transactions.where(operation_type: 101).last
    user.chargeback!(transaction, 'Received Date' => Time.zone.now.to_s, 'Transaction Date' => '2018-06-17', 'Cardholder Number' => '4815821234560709', 'Invoice Number' => 'ESPINDOLACRU', 'Chargeback Amount' => transaction.amount, 'Chargeback Category' => 'DEBITED', 'Chargeback Status' => 'OPEN', 'Chargeback Reason Code' => '1040', 'Chargeback Description' => 'Fraud - Card Absent Environment')

    chargeback_trans = user.transactions.where(operation_type: 110).last
    assert_equal chargeback_trans.amount, - transaction.amount
    assert user.lapsed?
  end

  test "Billing an user's membership when he was previously SD for credit_card_expired on different membership" do
    @terms_of_membership_with_gateway_yearly  = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    active_user                               = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway_yearly)
    active_merchant_stubs_payeezy(@sd_strategy, 'decline stubbed', false)
    active_user.bill_membership
    active_user.change_terms_of_membership(@terms_of_membership_with_gateway_yearly.id, 'changing tom', 100)

    active_merchant_stubs_payeezy
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count', 1) do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test 'Bill membership method sends membership_renewal communication each membership billing except the first one' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0)
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Communication.count', 1) do
        user.bill_membership
      end
    end
    assert_not_nil Communication.find_by_template_type 'membership_bill'
    assert_nil Communication.find_by_template_type 'membership_renewal'

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Communication.count', 2) do
        user.bill_membership
      end
      assert_not_nil Communication.find_by_template_type 'membership_renewal'
      assert_not_nil Communication.find_by_template_type 'membership_bill'
    end
  end
end
