class PayeezyTransactionTest < ActiveSupport::TestCase
  def setup
    active_merchant_stubs_payeezy
    @current_agent        = FactoryBot.create(:agent)
    @club                 = FactoryBot.create(:simple_club_with_payeezy_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @user                 = FactoryBot.build(:user)
    @credit_card          = FactoryBot.build(:credit_card_visa_payeezy)
    @hard_decline         = FactoryBot.create(:hard_decline_strategy, response_code: '502', gateway: 'payeezy')
    @soft_decline         = FactoryBot.create(:soft_decline_strategy, response_code: '522', gateway: 'payeezy')
    FactoryBot.create(:without_grace_period_decline_strategy_monthly, response_code: '9997', gateway: 'payeezy')
    FactoryBot.create(:without_grace_period_decline_strategy_yearly, response_code: '9997', gateway: 'payeezy')
  end

  test 'Enroll with Payeezy' do
    assert_difference('User.count', 1) do
      assert_difference('Transaction.count', 1) do
        enroll_user(@user, @terms_of_membership, 23, false, @credit_card)
      end
    end
  end

  test 'Bill membership with Payeezy' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    assert_difference('Transaction.count') do
      Timecop.travel(active_user.next_retry_bill_date) do
        active_user.bill_membership
        assert_equal active_user.reload.status, 'active'
      end
    end
  end

  test 'Completely refund a transaction with Payeezy' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount      = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      trans   = active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing)
      answer  = Transaction.refund(amount, trans.id)
      assert_equal answer[:code], '000', answer[:message]
      assert_equal trans.reload.refunded_amount, amount
      assert_equal trans.amount_available_to_refund, 0.0
    end
    assert_not_nil active_user.transactions.where(transaction_type: 'refund')
  end

  test 'Partial refund with Payeezy' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      trans           = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount = amount / 2
      answer          = Transaction.refund(refunded_amount, trans.id)
      assert_equal answer[:code], '000', answer[:message]
      assert_equal trans.reload.refunded_amount, refunded_amount
      assert_equal trans.amount_available_to_refund, trans.amount - refunded_amount
      assert_not_nil active_user.transactions.where("operation_type = ? and transaction_type = 'refund'", Settings.operation_types.credit)
    end
  end

  test 'Try billing an user when he was previously SD for credit_card_expired for Payeezy' do
    active_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    active_merchant_stubs_payeezy(@soft_decline.response_code, 'decline stubbed', false)
    Timecop.travel(active_user.next_retry_bill_date) { active_user.bill_membership }

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 5) do
        assert_difference('Transaction.count') do
          active_merchant_stubs_payeezy
          active_user.bill_membership
          assert_not_nil active_user.operations.find_by(operation_type: Settings.operation_types.membership_billing)
          assert_not_nil active_user.operations.find_by(operation_type: Settings.operation_types.renewal_scheduled)
          assert_not_nil active_user.operations.find_by(operation_type: Settings.operation_types.add_club_cash)
          assert_not_nil active_user.operations.find_by(operation_type: Settings.operation_types.membership_bill_email)
          assert_not_nil active_user.operations.find_by(operation_type: Settings.operation_types.automatic_recycle_credit_card)
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year + 2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      active_user.reload

      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end
end
