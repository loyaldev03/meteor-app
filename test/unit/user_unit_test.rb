require 'test_helper'

class UserUnitTest < ActiveSupport::TestCase
  setup do
    FactoryBot.create(:batch_agent)
    @club                = FactoryBot.create(:simple_club_with_gateway)
    Time.zone            = @club.time_zone
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    active_merchant_stubs_payeezy
  end

  test 'Create delayed jobs to desnormailze user data, preferences and sync against elastic search upon user creation' do
    user = FactoryBot.build(:user)
    assert !user.save, user.errors.inspect
    user.club = @terms_of_membership.club
    Delayed::Worker.delay_jobs = true
    assert_difference('Delayed::Job.count', 3) do
      assert user.save, "user cant be save #{user.errors.inspect}"
      assert_not_nil Delayed::Job.where("handler LIKE '%Users::AsyncElasticSearchIndexJob%'").first
      assert_not_nil Delayed::Job.where("handler LIKE '%Users::DesnormalizePreferencesJob%'").first
      assert_not_nil Delayed::Job.where("handler LIKE '%Users::DesnormalizeAdditionalDataJob%'").first
    end
    Delayed::Worker.delay_jobs = false
  end

  test 'show dates according to club timezones' do
    Time.zone                               = 'UTC'
    saved_user                              = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.member_since_date            = 'Wed, 02 May 2012 19:10:51 UTC 00:00'
    saved_user.current_membership.join_date = 'Wed, 03 May 2012 13:10:51 UTC 00:00'
    saved_user.next_retry_bill_date         = 'Wed, 03 May 2012 00:10:51 UTC 00:00'

    Time.zone                               = 'Eastern Time (US & Canada)'
    assert_equal I18n.l(Time.zone.at(saved_user.member_since_date.to_i)), '05/02/2012'
    assert_equal I18n.l(Time.zone.at(saved_user.next_retry_bill_date.to_i)), '05/02/2012'
    assert_equal I18n.l(Time.zone.at(saved_user.current_membership.join_date.to_i)), '05/03/2012'

    Time.zone = 'Ekaterinburg'
    assert_equal I18n.l(Time.zone.at(saved_user.member_since_date.to_i)), '05/03/2012'
    assert_equal I18n.l(Time.zone.at(saved_user.next_retry_bill_date.to_i)), '05/03/2012'
    assert_equal I18n.l(Time.zone.at(saved_user.current_membership.join_date.to_i)), '05/03/2012'
  end

  ################################################################
  ######## Credit Card update
  ################################################################

  test 'Method update_credit_card_from_drupal should update credit card' do
    user                    = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_credit_card    = user.active_credit_card

    # Configuring stubs to make sure to return a different token on next tokenization
    new_credit_card_params  = { number: '5199701234567892', expire_month: 1, expire_year: (Time.current + 3.years).year }.with_indifferent_access
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, '5199701234567892')

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count') do
        response = user.update_credit_card_from_drupal(new_credit_card_params)
        assert_equal response[:code], Settings.error_codes.success
        assert_nil user.active_credit_card.number
        assert_not_equal user.active_credit_card.id, original_credit_card.id
        assert_equal user.active_credit_card.token, CREDIT_CARD_TOKEN[new_credit_card_params[:number]]
        assert_not_nil user.reload.operations.find_by(operation_type: Settings.operation_types.credit_card_added)
        assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.credit_card_activated)
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add credit card, but update credit card only year' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    original_credit_card  = user.active_credit_card

    # 4000060001234562 is the number associated to the Factory credit_card
    ['4000060001234562', '4000-0600-0123-4562',
     '4000/0600/0123/4562', "XXXX-XXXX-XXXX-#{original_credit_card.last_digits}"].each_with_index do |credit_card_number, index|
      # Configuring stubs to make sure to return the same token
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

      new_year            = original_credit_card.expire_year + 3 + index
      credit_card_params  = { number: credit_card_number,
                              expire_month: original_credit_card.expire_month,
                              expire_year: new_year }.with_indifferent_access
      assert_difference('Operation.count') do
        assert_difference('CreditCard.count', 0) do
          response = user.update_credit_card_from_drupal(credit_card_params)
          assert_equal response[:code], Settings.error_codes.success
          assert_equal user.reload.active_credit_card.id, original_credit_card.id
          assert_equal user.active_credit_card.expire_month, original_credit_card.expire_month
          assert_equal user.active_credit_card.expire_year, new_year
          assert_not_nil user.reload.operations.find_by(operation_type: Settings.operation_types.credit_card_updated)
        end
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add credit card, but update credit card only month' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    original_credit_card  = user.active_credit_card

    # 4000060001234562 is the number associated to the Factory credit_card
    ['4000060001234562', '4000-0600-0123-4562',
     '4000/0600/0123/4562', "XXXX-XXXX-XXXX-#{original_credit_card.last_digits}"].each do |credit_card_number|
      # Configuring stubs to make sure to return the same token
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

      new_month           = ((1..12).to_a - [user.reload.active_credit_card.expire_month]).sample
      credit_card_params  = { number: credit_card_number,
                              expire_month: new_month,
                              expire_year: original_credit_card.expire_year }.with_indifferent_access
      assert_difference('Operation.count') do
        assert_difference('CreditCard.count', 0) do
          response = user.update_credit_card_from_drupal(credit_card_params)
          assert_equal response[:code], Settings.error_codes.success
          assert_equal user.reload.active_credit_card.id, original_credit_card.id
          assert_equal user.active_credit_card.expire_month, new_month
          assert_equal user.active_credit_card.expire_year, original_credit_card.expire_year
          assert_not_nil user.reload.operations.find_by(operation_type: Settings.operation_types.credit_card_updated)
        end
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add or update credit card with same information' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    original_credit_card  = user.active_credit_card

    # 4000060001234562 is the number associated to the Factory credit_card
    ['4000060001234562', '4000-0600-0123-4562',
     '4000/0600/0123/4562', "XXXX-XXXX-XXXX-#{original_credit_card.last_digits}"].each do |credit_card_number|
      # Configuring stubs to make sure to return the same token
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

      credit_card_params = { number: credit_card_number,
                             expire_month: original_credit_card.expire_month,
                             expire_year: original_credit_card.expire_year }.with_indifferent_access
      assert_difference('Operation.count', 0) do
        assert_difference('CreditCard.count', 0) do
          response = user.update_credit_card_from_drupal(credit_card_params)
          assert_equal response[:code], Settings.error_codes.success
          assert_equal response[:message], 'New expiration date its identically than the one we have in database.'
          assert_equal user.reload.active_credit_card.id, original_credit_card.id
        end
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add or update credit card when number is invalid' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    original_credit_card  = user.active_credit_card

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

    credit_card_params = { number: '12345',
                           expire_month: original_credit_card.expire_month,
                           expire_year: original_credit_card.expire_year }.with_indifferent_access
    response = user.update_credit_card_from_drupal(credit_card_params)
    assert_equal response[:code], Settings.error_codes.invalid_credit_card
    assert_equal response[:message], I18n.t('error_messages.invalid_credit_card')
    assert response[:errors][:number].include? 'is not a valid credit card number'
  end

  test 'Method update_credit_card_from_drupal does not add or update credit card when month is expired' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    user.active_credit_card

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

    # Testing this on a date that we are sure that we will allways be able to check expired months (Avoiding January).
    Timecop.travel(Date.new(Time.current.year + 1, 6)) do
      assert_difference('CreditCard.count', 0) do
        credit_card_params = { number: credit_card.number,
                             expire_month: Time.current.month - 1,
                             expire_year: Time.current.year }.with_indifferent_access
        response = user.update_credit_card_from_drupal(credit_card_params)
        assert_equal response[:code], Settings.error_codes.invalid_credit_card
        assert_equal response[:message], I18n.t('error_messages.invalid_credit_card')
        assert response[:errors][:expire_year].include? 'expired'
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add or update credit card when year is expired' do
    credit_card           = FactoryBot.build(:credit_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    user.active_credit_card

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

    assert_difference('CreditCard.count', 0) do
      credit_card_params = { number: credit_card.number,
                            expire_month: credit_card.expire_month,
                            expire_year: Time.current.year - 1 }.with_indifferent_access
      response = user.update_credit_card_from_drupal(credit_card_params)
      assert_equal response[:code], Settings.error_codes.invalid_credit_card
      assert_equal response[:message], I18n.t('error_messages.invalid_credit_card')
      assert response[:errors][:expire_year].include? 'expired'
    end
  end

  test 'Method update_credit_card_from_drupal activates old credit card' do
    credit_card           = FactoryBot.build(:credit_card)
    master_credit_card    = FactoryBot.build(:credit_card_master_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    original_credit_card  = user.active_credit_card

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, master_credit_card.number)
    credit_card_params = { number: master_credit_card.number,
                           expire_month: master_credit_card.expire_month,
                           expire_year: master_credit_card.expire_year }.with_indifferent_access
    assert_difference('CreditCard.count') do
      response = user.update_credit_card_from_drupal(credit_card_params)
      assert_equal response[:code], Settings.error_codes.success
      assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[master_credit_card.number]
    end

    # 4000060001234562 is the number associated to the Factory credit_card
    ['4000060001234562', '4000-0600-0123-4562', '4000/0600/0123/4562'].each_with_index do |credit_card_number, index|
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
      credit_card_params = { number: credit_card_number,
                             expire_month: credit_card.expire_month,
                             expire_year: credit_card.expire_year }.with_indifferent_access
      assert_difference('Operation.count') do
        assert_difference('CreditCard.count', 0) do
          response = user.update_credit_card_from_drupal(credit_card_params)
          assert_equal response[:code], Settings.error_codes.success
          assert_equal index + 1, user.operations.where(resource_id: original_credit_card.id, resource_type: 'CreditCard', operation_type: Settings.operation_types.credit_card_activated).count
          assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number]
        end
      end
      user.credit_cards.each { |cc| cc.update_attribute :active, !cc.active }
    end
  end

  test 'Method update_credit_card_from_drupal does not activates old expired credit card' do
    credit_card           = FactoryBot.build(:credit_card)
    master_credit_card    = FactoryBot.build(:credit_card_master_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    user.active_credit_card

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, master_credit_card.number)
    credit_card_params = { number: master_credit_card.number,
                           expire_month: master_credit_card.expire_month,
                           expire_year: master_credit_card.expire_year }.with_indifferent_access
    assert_difference('CreditCard.count') do
      response = user.update_credit_card_from_drupal(credit_card_params)
      assert_equal response[:code], Settings.error_codes.success
      assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[master_credit_card.number]
    end

    Timecop.travel(Date.new(credit_card.expire_year + 1)) do
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
      credit_card_params = { number: credit_card.number,
                             expire_month: credit_card.expire_month,
                             expire_year: credit_card.expire_year }.with_indifferent_access
      assert_difference('Operation.count', 0) do
        assert_difference('CreditCard.count', 0) do
          response = user.update_credit_card_from_drupal(credit_card_params)
          assert_equal response[:code], Settings.error_codes.invalid_credit_card
          assert_equal response[:message], I18n.t('error_messages.invalid_credit_card')
          assert response[:errors][:expire_year].include? 'expired'
          assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[master_credit_card.number]
        end
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not update credit card on blacklisted users' do
    credit_card           = FactoryBot.build(:credit_card)
    master_credit_card    = FactoryBot.build(:credit_card_master_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership, 23, false, credit_card)
    user.active_credit_card

    user.blacklist(Agent.last, 'testing')

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, master_credit_card.number)
    credit_card_params = { number: master_credit_card.number,
                           expire_month: master_credit_card.expire_month,
                           expire_year: master_credit_card.expire_year }.with_indifferent_access
    assert_difference('Operation.count', 0) do
      assert_difference('CreditCard.count', 0) do
        response = user.update_credit_card_from_drupal(credit_card_params)
        assert_equal response[:code], Settings.error_codes.blacklisted
        assert_equal response[:message], I18n.t('error_messages.user_set_as_blacklisted')
        assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number]
      end
    end
  end

  test 'Method update_credit_card_from_drupal does not add credit card if used by another user (Family memberships = false)' do
    credit_card           = FactoryBot.build(:credit_card)
    master_credit_card    = FactoryBot.build(:credit_card_master_card)
    @club.update_attribute :family_memberships_allowed, false
    enroll_user(FactoryBot.build(:user), @terms_of_membership.reload, 23, false, credit_card)
    second_user = enroll_user(FactoryBot.build(:user), @terms_of_membership.reload, 23, false, master_credit_card)

    # Configuring stubs to make sure to return the same token as the first user
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    credit_card_params = { number: credit_card.number,
                           expire_month: credit_card.expire_month,
                           expire_year: credit_card.expire_year }.with_indifferent_access
    assert_difference('Operation.count', 0) do
      assert_difference('CreditCard.count', 0) do
        response = second_user.update_credit_card_from_drupal(credit_card_params)
        assert_equal response[:code], Settings.error_codes.credit_card_in_use
        assert_equal response[:message], I18n.t('error_messages.credit_card_in_use', cs_phone_number: @club.cs_phone_number)
        assert response[:errors][:number].include? 'Credit card is already in use'
        assert_equal second_user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[master_credit_card.number]
      end
    end
  end

  test 'Method update_credit_card_from_drupal add credit card if used by another user (Family memberships = true)' do
    credit_card           = FactoryBot.build(:credit_card)
    master_credit_card    = FactoryBot.build(:credit_card_master_card)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership.reload, 23, false, credit_card)
    second_user           = enroll_user(FactoryBot.build(:user), @terms_of_membership.reload, 23, false, master_credit_card)
    assert @club.family_memberships_allowed

    # Configuring stubs to make sure to return the same token as the first user
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    credit_card_params = { number: credit_card.number,
                           expire_month: credit_card.expire_month,
                           expire_year: credit_card.expire_year }.with_indifferent_access
    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count', 1) do
        response = second_user.update_credit_card_from_drupal(credit_card_params)
        assert_equal response[:code], Settings.error_codes.success
        assert_equal user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number]
        assert_equal second_user.reload.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number]
      end
    end
  end

  ################################################################
  ######## Bill Date update
  ################################################################

  test 'Method change_next_bill_date updates billing date' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.update_attribute :recycled_times, 1

    new_next_bill_date = user.next_retry_bill_date + 3.months
    assert_difference('Operation.count') do
      response = user.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.success
      assert_equal response[:message], "Next bill date changed to #{new_next_bill_date.to_date} testing"
      assert_equal user.reload.bill_date.to_date, new_next_bill_date.to_date
      assert_equal user.next_retry_bill_date.to_date, new_next_bill_date.to_date
      assert_equal user.recycled_times, 0
    end
  end

  test 'Method change_next_bill_date does not update bill date when user is lapsed' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.set_as_canceled!

    new_next_bill_date = Time.current + 3.months
    assert_difference('Operation.count', 0) do
      response = user.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.next_bill_date_blank
      assert_equal response[:message], I18n.t('error_messages.unable_to_perform_due_user_status')
      assert_nil user.reload.bill_date
      assert_nil user.next_retry_bill_date
    end
  end

  test 'Method change_next_bill_date does not update bill date when user is applied status' do
    terms_of_membership_with_approval = FactoryBot.create(:terms_of_membership_with_gateway_and_approval_required, club_id: @club.id)
    user                              = enroll_user(FactoryBot.build(:user), terms_of_membership_with_approval)
    assert user.applied?

    new_next_bill_date = Time.current + 3.months
    assert_difference('Operation.count', 0) do
      response = user.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.next_bill_date_blank
      assert_equal response[:message], I18n.t('error_messages.unable_to_perform_due_user_status')
      assert_nil user.reload.bill_date
      assert_nil user.next_retry_bill_date
    end
  end

  test 'Method change_next_bill_date does not update bill date when TOM is not configured to expect payment' do
    terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, is_payment_expected: false)
    user                = enroll_user(FactoryBot.build(:user), terms_of_membership)
    user.next_retry_bill_date

    new_next_bill_date = Time.current + 3.months
    assert_difference('Operation.count', 0) do
      response = user.reload.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.user_not_expecting_billing
      assert_equal response[:message], I18n.t('error_messages.not_expecting_billing')
      assert_nil user.reload.bill_date
      assert_nil user.reload.next_retry_bill_date
    end
  end

  test 'Method change_next_bill_date does not update bill date with wrong format' do
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_bill_date  = user.next_retry_bill_date

    new_next_bill_date = '25012015'
    assert_difference('Operation.count', 0) do
      response = user.reload.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.wrong_data
      assert_equal response[:message], 'Next bill date wrong format.'
      assert_equal user.reload.next_retry_bill_date.to_date, original_bill_date.to_date
      assert_equal user.bill_date.to_date, original_bill_date.to_date
    end
  end

  test 'Method change_next_bill_date does not update bill date with date prior to today' do
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_bill_date  = user.next_retry_bill_date

    new_next_bill_date = Time.current - 2.days
    assert_difference('Operation.count', 0) do
      response = user.reload.change_next_bill_date(new_next_bill_date, nil, 'testing')
      assert_equal response[:code], Settings.error_codes.next_bill_date_prior_actual_date
      assert_equal response[:message], 'Next bill date should be older that actual date.'
      assert_equal user.reload.next_retry_bill_date.to_date, original_bill_date.to_date
      assert_equal user.bill_date.to_date, original_bill_date.to_date
    end
  end

  test 'Method change_next_bill_date does not update bill date with blank' do
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_bill_date  = user.next_retry_bill_date

    assert_difference('Operation.count', 0) do
      response = user.reload.change_next_bill_date('', nil, 'testing')
      assert_equal response[:code], Settings.error_codes.next_bill_date_blank
      assert_equal response[:message], I18n.t('error_messages.next_bill_date_blank')
      assert_equal user.reload.next_retry_bill_date.to_date, original_bill_date.to_date
      assert_equal user.bill_date.to_date, original_bill_date.to_date
    end
  end

  ################################################################
  ######## Cancel method
  ################################################################

  test 'Method cancel! does not allow set cancellation date without reason.' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    assert_difference('Operation.count', 0) do
      assert_nil user.cancel_date
      answer = user.cancel! Time.current + 10.days, ''
      assert_equal answer[:code], Settings.error_codes.cancel_reason_blank
      assert_equal answer[:message], 'Reason missing. Please, make sure to provide a reason for this cancelation.'
      assert_nil user.cancel_date
    end
  end

  test 'Method cancel! does not allow set cancellation date prior to today.' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    assert_difference('Operation.count', 0) do
      assert_nil user.cancel_date
      answer = user.cancel! Time.current - 1.days, 'testing'
      assert_equal answer[:code], Settings.error_codes.wrong_data
      assert_equal answer[:message], 'Cancellation date cannot be less or equal than today.'
      assert_nil user.cancel_date
    end
  end

  test 'Send communication upon cancellation' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    FactoryBot.create(:email_template, template_type: 'cancellation', terms_of_membership_id: @terms_of_membership.id)

    assert_difference('Communication.count') do
      user.set_as_canceled!
      assert_not_nil user.reload.communications.find_by(template_type: 'cancellation')
    end
  end
end
