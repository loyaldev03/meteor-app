require 'test_helper'

class UserEnrollmentTest < ActiveSupport::TestCase
  setup do
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    active_merchant_stubs_payeezy
  end

  def prepare_upgrade_downgrade_toms(options = {})
    options[:create_user]   ||= true
    options[:activate_user] ||= false
    options[:upgraded]      ||= false
    options[:cc_blank]      ||= false
    amount                    = options[:cc_blank] ? 0 : 23

    @upgraded_terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway_yearly, club_id: @club.id,
                                                                                                name: 'Upgraded Tom',
                                                                                                installment_amount: options[:upgraded] && options[:cc_blank] ? 0 : 100,
                                                                                                provisional_days: 90,
                                                                                                club_cash_installment_amount: 300
    @terms_of_membership          = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id,
                                                                                         name: 'Basic Tom',
                                                                                         installment_amount: !options[:upgraded] && options[:cc_blank] ? 0 : 10
    @credit_card                  = FactoryBot.build :credit_card
    @second_credit_card           = FactoryBot.build :credit_card_master_card
    @user                         = FactoryBot.build :user_with_api
    if options[:create_user]
      @saved_user = enroll_user(FactoryBot.build(:user), (options[:upgraded] ? @upgraded_terms_of_membership : @terms_of_membership), amount, options[:cc_blank])
      if options[:activate_user]
        Timecop.travel(@saved_user.next_retry_bill_date) { @saved_user.bill_membership }
        assert @saved_user.reload.active?
      end
    end
  end

  def validate_transactions_upon_tom_update(previous_membership, new_membership, amount_to_process, amount_in_favor, credit_card_set_active = true)
    if @saved_user.active?
      # tom_change_billing
      tom_change_billing_transaction = @saved_user.transactions.where('operation_type = ?', Settings.operation_types.tom_change_billing).last
      assert_equal tom_change_billing_transaction.amount, amount_to_process
      assert_equal tom_change_billing_transaction.terms_of_membership_id, new_membership.terms_of_membership_id
      assert_equal tom_change_billing_transaction.membership_id, new_membership.id
      # membership_balance_transfer
      transaction_balance_refund  = @saved_user.transactions.where('operation_type = ? and amount < 0', Settings.operation_types.membership_balance_transfer).last
      transaction_balance_sale    = @saved_user.transactions.where('operation_type = ? and amount > 0', Settings.operation_types.membership_balance_transfer).last
      if amount_in_favor && (amount_in_favor > 0)
        assert_equal transaction_balance_refund.amount, -amount_in_favor
        assert_equal transaction_balance_refund.terms_of_membership_id, previous_membership.terms_of_membership_id
        assert_equal transaction_balance_refund.membership_id, previous_membership.id
        assert_equal transaction_balance_sale.amount, amount_in_favor
        assert_equal transaction_balance_sale.terms_of_membership_id, new_membership.terms_of_membership_id
        assert_equal transaction_balance_sale.membership_id, new_membership.id
        if credit_card_set_active
          assert_equal transaction_balance_sale.last_digits, @saved_user.active_credit_card.last_digits
        else
          assert_not_equal transaction_balance_sale.last_digits, @saved_user.active_credit_card.last_digits
        end
      else
        assert_nil transaction_balance_refund
        assert_nil transaction_balance_sale
      end
    end
  end

  def enroll_user_with_error(user, tom, options = {} )
    amount      = options[:amount] || 23
    cc_blank    = options[:cc_blank] || false
    credit_card = options[:credit_card] || FactoryBot.build(:credit_card)
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number) unless options[:skip_stub]
    User.enroll(tom, nil, amount,
      { first_name: user.first_name,
        last_name: user.last_name, address: user.address, city: user.city, gender: 'M',
        zip: user.zip, state: user.state, email: user.email, type_of_phone_number: user.type_of_phone_number,
        phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code,
        phone_local_number: user.phone_local_number, country: 'US',
        product_sku: (options[:product_sku] || Settings.others_product) },
      { number: credit_card.number,
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)
  end

  ################################################################
  ######## Enrollment / Recovery methods
  ################################################################

  test 'Enrollment' do
    assert_difference('Operation.count', 4) do # EnrollBilling, club cash and EnrollmentInfo operations, fulfillment_creation
      assert_difference('Transaction.count', 1) do
        assert_difference('Fulfillment.count') do
          user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
          assert user.provisional?
          assert_not_nil user.next_retry_bill_date
          assert_equal user.join_date.to_date, Time.current.to_date
          assert_not_nil user.bill_date
          assert_equal user.recycled_times, 0
          assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.enrollment_billing, transaction_type: 'sale')
        end
      end
    end
  end

  test 'Enrollment with approval' do
    @tom_approval = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    assert_difference('Operation.count', 2) do
      assert_no_difference('Fulfillment.count') do
        user = enroll_user(FactoryBot.build(:user), @tom_approval)
        assert user.applied?
        assert_nil user.bill_date
        assert_nil user.next_retry_bill_date
        assert_equal user.join_date.to_date, Time.current.to_date
      end
    end
  end

  test 'Enrollment with blank credit card' do
    assert_difference('Operation.count', 4) do
      user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true)
      assert user.provisional?
      assert_equal user.join_date.to_date, Time.current.to_date
      assert_equal user.active_credit_card.token, CreditCard::BLANK_CREDIT_CARD_TOKEN
      assert_equal user.active_credit_card.last_digits, '0000'
      assert_equal user.active_credit_card.cc_type, 'unknown'
    end
  end

  test 'Enrollment fails when using duplicated email' do
    first_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    second_enrollment_response = enroll_user_with_error(FactoryBot.build(:user, email: first_user.email), @terms_of_membership)
    assert_difference('User.count', 0) do
      assert second_enrollment_response[:message].include? I18n.t('error_messages.user_already_active', cs_phone_number: @club.cs_phone_number)
      assert second_enrollment_response[:code].include? Settings.error_codes.user_already_active
      assert second_enrollment_response[:errors][:status].include? 'Already active.'
    end
  end

  test 'Enrollment fails when billing_enable is disabled' do
    @club.update_attribute :billing_enable, false
    assert_difference('User.count', 0) do
      response = enroll_user_with_error(FactoryBot.build(:user), @terms_of_membership.reload)
      assert response[:message].include? I18n.t('error_messages.club_is_not_enable_for_new_enrollments', cs_phone_number: @club.cs_phone_number)
      assert response[:code].include? Settings.error_codes.club_is_not_enable_for_new_enrollments
    end
  end

  test 'Enrollment does not create user if could not tokenize credit card' do
    assert_difference('User.count', 0) do
      active_merchant_stubs_payeezy('522', '', false, FactoryBot.build(:credit_card).number)
      response = enroll_user_with_error(FactoryBot.build(:user), @terms_of_membership.reload, skip_stub: true)
      assert_equal response[:message], I18n.t('error_messages.user_data_invalid')
      assert_equal response[:code], Settings.error_codes.user_data_invalid
    end
  end

  test 'Enrollment does not create user when there is a problem with transaction' do
    assert_difference('User.count', 0) do
      # Manually Stubing sale method to return error
      active_merchant_stubs_payeezy('522', '', false, FactoryBot.build(:credit_card).number)
      # Manually Stubing store method to return success
      active_merchant_stubs_store_payeezy
      enroll_user_with_error(FactoryBot.build(:user), @terms_of_membership.reload, skip_stub: true)
    end
  end

  test 'Enrollment does not create user when product is not available' do
    assert_difference('User.count', 0) do
      assert_difference('Membership.count', 0) do
        answer = enroll_user_with_error(FactoryBot.build(:user), @terms_of_membership.reload, product_sku: 'DOESNOTEXISTS')
        assert_equal answer[:code], Settings.error_codes.product_does_not_exists
        assert_equal answer[:message], I18n.t('error_messages.product_does_not_exists')
      end
    end
  end

  test 'Enrollment does not create user when product does not have stock' do
    product = FactoryBot.create(:random_product, club_id: @club.id, stock: 0)
    assert_difference('User.count', 0) do
      assert_difference('Membership.count', 0) do
        answer = enroll_user_with_error(FactoryBot.build(:user), @terms_of_membership.reload, product_sku: product.sku)
        assert_equal answer[:code], Settings.error_codes.product_out_of_stock
        assert_equal answer[:message], I18n.t('error_messages.product_out_of_stock')
      end
    end
  end

  test 'User gets club cash upon enrollment based on terms of membership configuration' do
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway,
                                             club_id: @club.id, initial_club_cash_amount: 0)
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_equal user.club_cash_amount, 0

    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway,
                                             club_id: @club.id, initial_club_cash_amount: 100)
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_equal user.club_cash_amount, 100
  end

  test 'Active user cant be recovered' do
    user    = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    tom_dup = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    answer  = user.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.user_already_active, answer[:message]
  end

  test 'Lapsed user can be recovered' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.set_as_canceled!
    old_membership_id = user.current_membership_id
    answer            = user.recover(@terms_of_membership, nil, { product_sku: Settings.others_product })
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'provisional', user.status, 'Status was not updated.'
    assert_not_equal user.current_membership_id, old_membership_id
    assert_nil user.current_membership.parent_membership_id
  end

  test 'Lapsed user can be recovered (through enroll method) and updated' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.set_as_canceled!
    old_membership_id = user.current_membership_id
    user_information = FactoryBot.build(:user, email: user.email)
    enroll_user(user_information, @terms_of_membership)
    assert_equal 'provisional', user.reload.status, 'Status was not updated.'
    assert_not_equal user.current_membership_id, old_membership_id
    assert_nil user.current_membership.parent_membership_id
    %i[first_name last_name address state city country zip].each do |attribute|
      assert_equal user.send(attribute), user_information.send(attribute)
    end
  end

  test 'Lapsed user is not recovered nor information is updated when recovery fails (trough enroll method)' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.set_as_canceled!
    old_membership_id = user.current_membership_id
    user_information = FactoryBot.build(:user, email: user.email)
    enroll_user_with_error(user_information, @terms_of_membership)
    assert_equal 'provisional', user.reload.status, 'Status was not updated.'
    assert_not_equal user.current_membership_id, old_membership_id
    assert_nil user.current_membership.parent_membership_id
    %i[first_name last_name address state city country zip].each do |attribute|
      assert_equal user.send(attribute), user.send(attribute)
    end
  end

  test 'Lapsed user can be recovered unless it needs approval' do
    tom_approval  = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    user          = enroll_user(FactoryBot.build(:user), tom_approval)
    answer        = {}
    user.set_as_canceled!
    Delayed::Worker.delay_jobs = true
    assert_difference('DelayedJob.count', 2) do # :send_recover_needs_approval_email_dj_without_delay, :asyn_solr_index_without_delay
      answer = user.recover(tom_approval)
    end
    Delayed::Worker.delay_jobs = false
    Delayed::Job.all.each(&:invoke_job)
    user.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', user.status
  end

  test 'Lapsed user should have cancel date set' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_nil user.cancel_date
    cancelation_date = (Time.zone.now + 2.days).to_date
    user.cancel! cancelation_date, 'Cancel from Unit Test'
    Timecop.travel(cancelation_date) { user.set_as_canceled! }
    user.reload
    assert_not_nil user.cancel_date
    assert user.cancel_date > user.join_date
  end

  ################################################################
  ######## Change of membership methods
  ################################################################

  test 'Save the sale method updates membership' do
    @terms_of_membership2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    saved_user            = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    old_membership_id     = saved_user.current_membership_id

    assert_difference('Membership.count', 1) do
      saved_user.save_the_sale @terms_of_membership2.id
    end
    assert_equal  saved_user.current_membership.status, saved_user.status
    assert_nil    saved_user.current_membership.cancel_date
    assert_equal  saved_user.current_membership.parent_membership_id, old_membership_id
  end

  test 'Save the sale method does not update membership when user is applied' do
    tom_approval      = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    saved_user        = enroll_user(FactoryBot.build(:user), tom_approval)
    old_membership_id = saved_user.current_membership_id
    assert saved_user.applied?

    assert_difference('Membership.count', 0) do
      assert_difference('Operation.count', 0) do
        response = saved_user.save_the_sale @terms_of_membership.id
        assert_equal response[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal response[:code], Settings.error_codes.user_status_dont_allow
      end
    end
    assert saved_user.applied?
    assert_equal saved_user.current_membership_id, old_membership_id
  end

  test 'Save the sale method does not update membership when user is lapsed' do
    saved_user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    old_membership_id = saved_user.current_membership_id
    saved_user.set_as_canceled!
    assert saved_user.lapsed?

    assert_difference('Membership.count', 0) do
      assert_difference('Operation.count', 0) do
        response = saved_user.save_the_sale @terms_of_membership.id
        assert_equal response[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal response[:code], Settings.error_codes.user_status_dont_allow
      end
    end
    assert saved_user.lapsed?
    assert_equal saved_user.current_membership_id, old_membership_id
  end

  test 'Save the sale method does not update next retry bill date' do
    @terms_of_membership2           = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    saved_user                      = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_bill_date              = saved_user.bill_date
    original_next_retry_bill_date   = saved_user.next_retry_bill_date
    assert_difference('Membership.count', 1) do
      saved_user.save_the_sale @terms_of_membership2.id
    end
    assert_equal saved_user.reload.bill_date, original_bill_date
    assert_equal saved_user.reload.next_retry_bill_date, original_next_retry_bill_date
  end

  test 'Save the sale method removes club cash only when specified' do
    @terms_of_membership2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    saved_user            = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.add_club_cash 100, 'testing'
    original_club_cash = saved_user.club_cash_amount

    assert_difference('Membership.count') do
      assert_difference('ClubCashTransaction.count', 0) do
        saved_user.save_the_sale @terms_of_membership2.id
        assert_equal saved_user.reload.club_cash_amount, original_club_cash
      end
    end
    assert_difference('Membership.count') do
      assert_difference('ClubCashTransaction.count') do
        saved_user.save_the_sale @terms_of_membership.id, nil, nil, remove_club_cash: true
        assert_equal saved_user.reload.club_cash_amount, 0
      end
    end
  end

  test 'Change terms of membership method does not create membership when passing the same tom' do
    saved_user              = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_membership_id  = saved_user.current_membership_id
    assert_difference('Membership.count', 0) do
      answer = saved_user.change_terms_of_membership @terms_of_membership, 'testing', Settings.operation_types.save_the_sale
      assert_equal answer[:message], 'Nothing to change. Member is already enrolled on that TOM.'
      assert_equal answer[:code], Settings.error_codes.nothing_to_change_tom
    end
    assert_equal saved_user.current_membership_id, original_membership_id
  end

  test 'Save the sale method does not update membership upon failure' do
    @terms_of_membership2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @saved_user           = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    stubed_answer         = { code: 500, message: 'Error on save the sale.' }
    User.any_instance.stubs(:enroll).returns(stubed_answer)

    former_membership_id = @saved_user.current_membership_id
    assert_difference('Membership.count', 0) do
      answer = @saved_user.save_the_sale @terms_of_membership2.id
      assert_equal answer, stubed_answer
    end
    assert_equal @saved_user.current_membership_id, former_membership_id
  end

  test 'Downgrade method sets parent_membership_id and next bill date.' do
    terms_of_membership_with_gateway_to_downgrade = FactoryBot.create(:terms_of_membership_for_downgrade, club_id: @club.id)
    @terms_of_membership.update_attributes(if_cannot_bill: 'downgrade_tom', downgrade_tom_id: terms_of_membership_with_gateway_to_downgrade.id)
    saved_user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    old_membership_id = saved_user.current_membership_id
    assert_difference('Membership.count') do
      saved_user.downgrade_user
    end
    assert_equal saved_user.current_membership.parent_membership_id, old_membership_id
    assert_equal saved_user.current_membership.utm_medium, Membership::CS_UTM_MEDIUM_DOWNGRADE
    assert_equal saved_user.current_membership.utm_campaign, Membership::CS_UTM_CAMPAIGN
    # sets next_retry_bill_date according to new terms of membership.
    assert_equal saved_user.bill_date.to_date, (saved_user.current_membership.join_date + saved_user.terms_of_membership.provisional_days.days).to_date
    assert_equal saved_user.next_retry_bill_date.to_date, (saved_user.current_membership.join_date + saved_user.terms_of_membership.provisional_days.days).to_date
  end

  test 'Downgrade method succeeds even when the user has invalid information' do
    terms_of_membership_with_gateway_to_downgrade = FactoryBot.create(:terms_of_membership_for_downgrade, club_id: @club.id)
    @terms_of_membership.update_attributes(if_cannot_bill: 'downgrade_tom', downgrade_tom_id: terms_of_membership_with_gateway_to_downgrade.id)
    saved_user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.zip    = 123
    saved_user.save validate: false
    assert_difference('Membership.count') do
      saved_user.downgrade_user
    end
    assert_equal saved_user.current_membership.terms_of_membership_id, terms_of_membership_with_gateway_to_downgrade.id
  end

  test 'Upgrade method should fill parent_membership_id' do
    terms_of_membership2 = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @terms_of_membership.upgrade_tom_id = terms_of_membership2.id
    @terms_of_membership.upgrade_tom_period = 0
    @terms_of_membership.save(validate: false)
    saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    old_membership_id = saved_user.current_membership_id
    Timecop.travel(saved_user.next_retry_bill_date) do
      saved_user.bill_membership
    end
    assert_equal saved_user.current_membership.parent_membership_id, old_membership_id
    assert_equal saved_user.current_membership.utm_medium, Membership::CS_UTM_MEDIUM_UPGRADE
    assert_equal saved_user.current_membership.utm_campaign, Membership::CS_UTM_CAMPAIGN
  end


  test 'Change terms of membership UPGRADE ACTIVE user' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@terms_of_membership.club_cash_installment_amount * (days_until_nbd / @terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 8) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash - prorated_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user (OldTom provisional_days = days spent in OldTom < NewTom provisional days)' do
    prepare_upgrade_downgrade_toms
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount

    Timecop.travel(@saved_user.next_retry_bill_date) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@terms_of_membership.club_cash_installment_amount * (days_until_nbd / @terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 6) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user (OldTom provisional_days < days spent in OldTom < NewTom provisional days)' do
    prepare_upgrade_downgrade_toms
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = 0
      amount_to_process   = @upgraded_terms_of_membership.installment_amount
      # amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      # amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      assert_difference('Operation.count', 6) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user (OldTom provisional_days = days spent in OldTom > NewTom provisional days)' do
    prepare_upgrade_downgrade_toms
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount

    # configuring provisional_periods for both yearly_tom to be less than current
    @upgraded_terms_of_membership.provisional_days = @terms_of_membership.provisional_days / 2
    @upgraded_terms_of_membership.save(validate: false)

    Timecop.travel(@saved_user.next_retry_bill_date) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@terms_of_membership.club_cash_installment_amount * (days_until_nbd / @terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 8) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert @saved_user.active?
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user (OldTom provisional_days > days spent in OldTom > NewTom provisional_days)' do
    prepare_upgrade_downgrade_toms
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount

    # configuring provisional_periods for both yearly_tom to be less than current
    @upgraded_terms_of_membership.provisional_days = @terms_of_membership.provisional_days / 2
    @upgraded_terms_of_membership.save(validate: false)

    Timecop.travel(@saved_user.next_retry_bill_date - 1.day) do
      amount_in_favor     = 0
      amount_to_process   = @upgraded_terms_of_membership.installment_amount
      assert_difference('Operation.count', 8) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert @saved_user.active?
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user where it was declined before. (OldTom provisional_days > days spent in OldTom > NewTom provisional_days)' do
    prepare_upgrade_downgrade_toms
    sd_strategy         = FactoryBot.create(:soft_decline_strategy)
    credit_card_params  = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership = @saved_user.current_membership

    Timecop.travel(@saved_user.next_retry_bill_date) { @saved_user.bill_membership }
    active_merchant_stubs_payeezy(sd_strategy.response_code, 'Transaction Declined with Stub', false, @credit_card.number)
    Timecop.travel(@saved_user.next_retry_bill_date) { @saved_user.bill_membership }
    active_merchant_stubs_payeezy
    original_club_cash = @saved_user.reload.club_cash_amount

    Timecop.travel(@saved_user.bill_date + rand(1..6).days) do
      amount_in_favor     = 0
      amount_to_process   = @upgraded_terms_of_membership.installment_amount
      assert_difference('Operation.count', 8) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert @saved_user.active?
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE ACTIVE user set new credit card as active when current is blank.' do
    prepare_upgrade_downgrade_toms(activate_user: true, cc_blank: true)
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_club_cash          = @saved_user.club_cash_amount
    previous_membership         = @saved_user.current_membership

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@terms_of_membership.club_cash_installment_amount * (days_until_nbd / @terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 8) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash - prorated_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE PROVISIONAL user set new credit card as active when current is blank. (days spent in OldTom < NewTom provisional_days)' do
    prepare_upgrade_downgrade_toms(blank_cc: true)
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_club_cash          = @saved_user.club_cash_amount
    previous_membership         = @saved_user.current_membership

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = 0
      assert_difference('Operation.count', 6) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert @saved_user.provisional?
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership UPGRADE ACTIVE user do not set new credit card as active.' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    credit_card_params          = { set_active: 0, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_club_cash          = @saved_user.club_cash_amount
    previous_membership         = @saved_user.current_membership

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@terms_of_membership.installment_amount.to_f * (days_until_nbd / @terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@upgraded_terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@terms_of_membership.club_cash_installment_amount * (days_until_nbd / @terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 7) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
      assert_equal @saved_user.reload.terms_of_membership.id, @upgraded_terms_of_membership.id
      assert_not_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
      assert_equal @saved_user.club_cash_amount, original_club_cash - prorated_club_cash + @upgraded_terms_of_membership.club_cash_installment_amount
      validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
    end
  end

  test 'Change terms of membership do not UPGRADE ACTIVE user with credit card invalid or expired.' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    original_membership       = @saved_user.current_membership
    expired_credit_card_param = { number: '4111111111111112', expire_month: @second_credit_card.expire_month, expire_year: '2014' }.with_indifferent_access
    invalid_credit_card_param = { number: '12873129', expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    [invalid_credit_card_param, expired_credit_card_param].each do |cc_params|
      assert_difference('Operation.count', 0) do
        assert_difference('Membership.count', 0) do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, cc_params)
          assert_equal answer[:code], Settings.error_codes.invalid_credit_card
          assert_equal answer[:message], I18n.t('error_messages.invalid_credit_card')
        end
      end
      assert_equal @saved_user.reload.current_membership_id, original_membership.id
    end
  end

  test 'Change terms of membership do not UPGRADE PROVISIONAL user with credit card invalid or expired.' do
    prepare_upgrade_downgrade_toms
    original_membership       = @saved_user.current_membership
    expired_credit_card_param = { number: '4111111111111112', expire_month: @second_credit_card.expire_month, expire_year: '2014' }.with_indifferent_access
    invalid_credit_card_param = { number: '12873129', expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    [invalid_credit_card_param, expired_credit_card_param].each do |cc_params|
      assert_difference('Operation.count', 0) do
        assert_difference('Membership.count', 0) do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, cc_params)
          assert_equal answer[:code], Settings.error_codes.invalid_credit_card
          assert_equal answer[:message], I18n.t('error_messages.invalid_credit_card')
        end
      end
      assert_equal @saved_user.reload.current_membership_id, original_membership.id
    end
  end

  test 'Change terms of membership DOWNGRADE ACTIVE user set new credit card as active.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    credit_card_params          = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    previous_membership         = @saved_user.current_membership
    original_club_cash          = @saved_user.club_cash_amount
    amount_in_favor             = 0
    amount_to_process           = 0
    prorated_club_cash          = 0

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor     = ((@upgraded_terms_of_membership.installment_amount.to_f * (days_until_nbd / @upgraded_terms_of_membership.installment_period.to_f)) * 100).round / 100.0
      amount_to_process   = ((@terms_of_membership.installment_amount - amount_in_favor) * 100).round / 100.0
      prorated_club_cash  = (@upgraded_terms_of_membership.club_cash_installment_amount * (days_until_nbd / @upgraded_terms_of_membership.installment_period.to_f)).round
      assert_difference('Operation.count', 10) do
        assert_difference('Membership.count') do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
          assert_equal answer[:code], Settings.error_codes.success
        end
      end
    end
    assert_equal @saved_user.reload.terms_of_membership.id, @terms_of_membership.id
    assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
    assert_equal @saved_user.club_cash_amount, original_club_cash - prorated_club_cash + @terms_of_membership.club_cash_installment_amount
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor, credit_card_params[:set_active])
  end

  test 'Change terms of membership do not DOWNGRADE ACTIVE user with credit card invalid or expired.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    original_membership       = @saved_user.current_membership
    expired_credit_card_param = { number: '4111111111111112', expire_month: @second_credit_card.expire_month, expire_year: '2014' }.with_indifferent_access
    invalid_credit_card_param = { number: '12873129', expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    [invalid_credit_card_param, expired_credit_card_param].each do |cc_params|
      assert_difference('Operation.count', 0) do
        assert_difference('Membership.count', 0) do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, cc_params)
          assert_equal answer[:code], Settings.error_codes.invalid_credit_card
          assert_equal answer[:message], I18n.t('error_messages.invalid_credit_card')
        end
      end
      assert_equal @saved_user.reload.current_membership_id, original_membership.id
    end
  end

  test 'Change terms of membership do not DOWNGRADE PROVISIONAL user with credit card invalid or expired.' do
    prepare_upgrade_downgrade_toms(upgraded: true)
    original_membership       = @saved_user.current_membership
    expired_credit_card_param = { number: '4111111111111112', expire_month: @second_credit_card.expire_month, expire_year: '2014' }.with_indifferent_access
    invalid_credit_card_param = { number: '12873129', expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    [invalid_credit_card_param, expired_credit_card_param].each do |cc_params|
      assert_difference('Operation.count', 0) do
        assert_difference('Membership.count', 0) do
          # stubing payment gateway to return token related to new CC
          active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
          answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, cc_params)
          assert_equal answer[:code], Settings.error_codes.invalid_credit_card
          assert_equal answer[:message], I18n.t('error_messages.invalid_credit_card')
        end
      end
      assert_equal @saved_user.reload.current_membership_id, original_membership.id
    end
  end

  test 'Change terms of membership DOWNGRADE ACTIVE does not set negative club cash if has to remove more than available.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    credit_card_params = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    @saved_user.add_club_cash Agent.first, -(@saved_user.club_cash_amount - 1), 'testing'
    assert_equal @saved_user.club_cash_amount, 1

    Timecop.travel(@saved_user.next_retry_bill_date - (@saved_user.terms_of_membership.installment_period / 2).days) do
      days_until_nbd      = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      prorated_club_cash  = (@upgraded_terms_of_membership.initial_club_cash_amount * (days_until_nbd / @upgraded_terms_of_membership.installment_period.to_f)).round
      assert_difference('Membership.count') do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.success
      end
      assert prorated_club_cash > 1
      assert_equal @saved_user.reload.club_cash_amount, 0
      assert_equal @saved_user.reload.terms_of_membership_id, @terms_of_membership.id
    end
  end

  test 'Change terms of membership UPGRADE ACTIVE is not allowed when user was already refunded.' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    membership_transaction  = @saved_user.transactions.where('operation_type = ?', Settings.operation_types.membership_billing).last
    Transaction.refund(membership_transaction.amount / 2, membership_transaction.id)

    Timecop.travel(@saved_user.next_retry_bill_date + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.error_on_prorated_enroll
        assert_equal answer[:message], I18n.t('error_messages.prorated_enroll_failure', cs_phone_number: @saved_user.club.cs_phone_number)
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end

  test 'Change terms of membership DOWNGRADE ACTIVE is not allowed when user was already refunded.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    membership_transaction  = @saved_user.transactions.where('operation_type = ?', Settings.operation_types.membership_billing).last
    Transaction.refund(membership_transaction.amount / 2, membership_transaction.id)

    Timecop.travel(@saved_user.next_retry_bill_date + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.error_on_prorated_enroll
        assert_equal answer[:message], I18n.t('error_messages.prorated_enroll_failure', cs_phone_number: @saved_user.club.cs_phone_number)
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end

  test 'Change terms of membership UPGRADE is not allowed on LAPSED users.' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    @saved_user.set_as_canceled!

    Timecop.travel(Time.current + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.user_status_dont_allow
        assert_equal answer[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end

  test 'Change terms of membership DOWNGRADE is not allowed on LAPSED users.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    @saved_user.set_as_canceled!

    Timecop.travel(Time.current + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.user_status_dont_allow
        assert_equal answer[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end

  test 'Change terms of membership UPGRADE is not allowed on APPLIED users.' do
    prepare_upgrade_downgrade_toms(activate_user: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    @saved_user.set_as_applied!

    Timecop.travel(Time.current + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@upgraded_terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.user_status_dont_allow
        assert_equal answer[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end

  test 'Change terms of membership DOWNGRADE is not allowed on APPLIED users.' do
    prepare_upgrade_downgrade_toms(activate_user: true, upgraded: true)
    credit_card_params      = { set_active: 1, number: @second_credit_card.number, expire_month: @second_credit_card.expire_month, expire_year: @second_credit_card.expire_year }.with_indifferent_access
    original_membership     = @saved_user.current_membership
    @saved_user.set_as_applied!

    Timecop.travel(Time.current + (@saved_user.terms_of_membership.installment_period / 2).days) do
      assert_difference('Membership.count', 0) do
        # stubing payment gateway to return token related to new CC
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @second_credit_card.number)
        answer = @saved_user.change_terms_of_membership(@terms_of_membership, 'testing', Settings.operation_types.update_terms_of_membership, nil, true, credit_card_params)
        assert_equal answer[:code], Settings.error_codes.user_status_dont_allow
        assert_equal answer[:message], 'Member status does not allows us to change the subscription plan.'
        assert_equal original_membership.id, @saved_user.reload.current_membership.id
      end
    end
  end
end
