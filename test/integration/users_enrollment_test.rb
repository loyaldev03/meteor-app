require 'test_helper'

class UsersEnrollmentTest < ActionDispatch::IntegrationTest
  setup do
    active_merchant_stubs_payeezy
    @admin_agent                        = FactoryBot.create(:confirmed_admin_agent)
    @club                               = FactoryBot.create(:simple_club_with_gateway)
    @partner                            = @club.partner
    Time.zone                           = @club.time_zone
    @terms_of_membership_with_gateway   = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_approval  = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    sign_in_as(@admin_agent)
  end

  def setup_email_templates
    [[7, 'Trial'], [35, 'News'], [40, 'Deals'], [45, 'Local Chapters'], [50, 'VIP']].each do |data|
      FactoryBot.create(:email_template_for_action_mailer, name: "Day #{data[0]} - #{data[1]}", days: data[0], terms_of_membership_id: @terms_of_membership_with_gateway.id)
    end
  end

  def validate_terms_of_membership_show_page(saved_user)
    within('#table_membership_information') do
      within('#td_mi_terms_of_membership_name') { click_link_or_button("#{saved_user.terms_of_membership.name}") }
    end
    within('#div_description_feature') do
      assert page.has_content?(@terms_of_membership_with_gateway.name) if @terms_of_membership_with_gateway.name
      assert page.has_content?(@terms_of_membership_with_gateway.description) if @terms_of_membership_with_gateway.description
      assert page.has_content?(@terms_of_membership_with_gateway.provisional_days.to_s) if @terms_of_membership_with_gateway.provisional_days
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s) if @terms_of_membership_with_gateway.installment_amount
      # assert page.has_content?(@terms_of_membership_with_gateway.grace_period.to_s) if @terms_of_membership_with_gateway.grace_period
    end
    within('#table_email_template') do
      EmailTemplate::TEMPLATE_TYPES.each do |type|
        if type != :pillar
          if saved_user.current_membership.terms_of_membership.needs_enrollment_approval
            assert page.has_content?("Test #{type}")
          elsif type != :rejection
            assert page.has_content?("Test #{type}")
          end
        end
      end
      EmailTemplate.where(terms_of_membership_id: saved_user.terms_of_membership.id).each do |et|
        assert page.has_content?(et.client)
        assert page.has_content?(et.template_type)
        assert page.has_content?(et.external_attributes.to_s)
      end
    end
  end

  def generate_operations(user)
    FactoryBot.create(:operation_profile, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.enrollment_billing, description: 'user was enrolled')
    FactoryBot.create(:operation_profile, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.cancel, description: 'Blacklisted user. Reason: Too much spam')
    FactoryBot.create(:operation_profile, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.save_the_sale, description: 'Blacklisted user. Reason: dont like it')
    FactoryBot.create(:operation_profile, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.recovery, description: 'Blacklisted user. Reason: testing')
    FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.active_email, description: 'Communication sent successfully')
    FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.prebill_email, description: 'Communication was not sent')
    FactoryBot.create(:operation_other, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.others, description: 'user updated successfully')
    FactoryBot.create(:operation_other, created_by_id: @admin_agent.id, resource_type: 'user', user_id: user.id, operation_type: Settings.operation_types.others, description: 'user was recovered')
  end

  # When creating user from web, should add KIT and CARD fulfillments
  def validate_timezone_dates(timezone)
    @club.time_zone = timezone
    @club.save
    Time.zone = timezone
    @saved_user.reload
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#td_mi_member_since_date') { assert page.has_content?(I18n.l(@saved_user.member_since_date, :format => :only_date)) }
    within('#td_mi_join_date') { assert page.has_content?(I18n.l(@saved_user.join_date, :format => :only_date)) }
    within('#td_mi_next_retry_bill_date') { assert page.has_content?(I18n.l(@saved_user.next_retry_bill_date, :format => :only_date)) }
    within('#td_mi_credit_cards_first_created_at') { assert page.has_content?(I18n.l(@saved_user.credit_cards.first.created_at, :format => :only_date)) }
  end

  def confirm_email_is_sent(amount_of_days, template_name)
    setup_email_templates
    @saved_user = create_user_by_sloop(@admin_agent, FactoryBot.build(:user), FactoryBot.build(:credit_card_master_card), FactoryBot.build(:membership_with_enrollment_info), @terms_of_membership_with_gateway)
    @saved_user.current_membership.update_attribute(:join_date, Time.zone.now - amount_of_days.day)
    assert_difference('Communication.count') do
      excecute_like_server(@club.time_zone) { TasksHelpers.send_pillar_emails }
    end
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Communications' }
    within('#communications') { assert page.has_content?(template_name) }
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { select 'communications', from: 'operation[operation_type]' }
  end

  test 'create user' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    created_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name)

    validate_view_user_base(created_user)
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within('#table_enrollment_info') { assert page.has_content?(I18n.t('activerecord.attributes.user.has_no_preferences_saved')) }
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert page.has_content?('Authorization : Transaction Normal - Approved with Stub') }
    within('.nav-tabs') { click_on 'Fulfillments' }
    within('#fulfillments') { assert page.has_content?(created_user.fulfillments.first.product_sku) }
    assert_equal(Fulfillment.count, 1)
    assert_equal created_user.fulfillments.last.product_sku, created_user.current_membership.product_sku
    assert_equal created_user.fulfillments.last.product_id, Product.find_by(sku: created_user.current_membership.product_sku, club_id: created_user.club_id).id
  end

  # Reject new enrollments if billing is disable
  test 'create user with billing disabled' do
    @club.update_attribute :billing_enable, false
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    fill_in_user(unsaved_user)
    assert page.has_content? I18n.t('error_messages.club_is_not_enable_for_new_enrollments', cs_phone_number: @club.cs_phone_number)
  end

  test 'Create an user with CC blank' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    created_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name, true)

    validate_view_user_base(created_user)
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations_table') { assert page.has_content?('Member enrolled successfully $0.0') }
  end

  test 'show dates according to club timezones' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    validate_timezone_dates('Eastern Time (US & Canada)')
    validate_timezone_dates('Ekaterinburg')
  end

  test 'do not allow to create a user without information' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    visit new_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @club.name)
    within('#table_demographic_information') do
      select('United States', from: 'user[country]')
    end
    alert_ok_js
    click_link_or_button 'Create User'
    within('#table_contact_information') do
      assert find_field('user[phone_country_code]').value == '1' # Because it is set to its default value when lost focus
    end
    within('#error_explanation') do
      assert page.has_content?("first_name: can't be blank,is invalid"), 'Failure on first_name validation message'
      assert page.has_content?("last_name: can't be blank,is invalid"), 'Failure on last_name validation message'
      assert page.has_content?('email: email address is invalid'), 'Failure on email validation message'
      assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 character)"), 'Failure on phone_area_code validation message'
      assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 character)"), 'Failure on phone_local_number validation message'
      assert page.has_content?('address: is invalid'), 'Failure on address validation message'
      assert page.has_content?("state: can't be blank,is invalid"), 'Failure on state validation message'
      assert page.has_content?("city: can't be blank,is invalid"), 'Failure on city validation message'
      assert page.has_content?("zip: can't be blank,The zip code is not valid for the selected country."), 'Failure on zip validation message'
    end
  end

  test 'do not allow to create a user with invalid characters' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    visit new_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @club.name)
    within('#table_demographic_information') do
      fill_in 'user[first_name]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in 'user[address]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in 'user[city]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in 'user[last_name]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in 'user[zip]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      select('United States', from: 'user[country]')
      within('#states_td') do
        select('Colorado', from: 'user[state]')
      end
    end
    within('#table_contact_information') do
      fill_in 'user[email]', with: '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
    end
    alert_ok_js
    click_link_or_button 'Create User'
    within('#error_explanation') do
      assert page.has_content?('first_name: is invalid'), 'Failure on first_name validation message'
      assert page.has_content?('last_name: is invalid'), 'Failure on last_name validation message'
      assert page.has_content?('email: email address is invalid'), 'Failure on email validation message'
      assert page.has_content?('address: is invalid'), 'Failure on address validation message'
      assert page.has_content?('city: is invalid'), 'Failure on city validation message'
      assert page.has_content?('zip: The zip code is not valid for the selected country.'), 'Failure on zip validation message'
    end
  end

  test 'do not allow to create a user with invalid email' do
    visit new_user_path(partner_prefix: @club.partner.prefix, club_prefix: @club.name)
    within('#table_contact_information') do
      fill_in 'user[email]', with: 'asdfhomail.com'
    end
    within('#table_demographic_information') do
      select('United States', from: 'user[country]')
    end
    alert_ok_js
    click_link_or_button 'Create User'
    within('#error_explanation') do
      assert page.has_content?('email: email address is invalid'), 'Failure on email validation message'
    end
  end

  # return to user's profile from terms of membership
  test 'show terms of membership' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    validate_terms_of_membership_show_page(@saved_user)
    click_link_or_button('Return')
  end

  test 'create user with gender male and female' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id, gender: 'M')
    create_user(unsaved_user)
    assert find_field('input_gender').value == 'Male'
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id, gender: 'F')
    create_user(unsaved_user)
    assert find_field('input_gender').value == 'Female'
  end

  test 'create user without phone number' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id, phone_country_code: nil, phone_area_code: nil, phone_local_number: nil)
    fill_in_user(unsaved_user)
    within('#error_explanation') do
      assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 character)")
      assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 character)")
    end
  end

  test 'should create user and display type of phone number' do
    unsaved_user  = FactoryBot.build(:active_user, club_id: @club.id, type_of_phone_number: 'home')
    credit_card   = FactoryBot.build(:credit_card_master_card)
    saved_user    = create_user(unsaved_user, credit_card)
    validate_view_user_base(saved_user)
  end

  test 'should not let bill date to be edited' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    click_link_or_button 'Edit'

    assert page.has_no_selector?('user[bill_date]')
    within('#table_demographic_information') do
      assert page.has_no_selector?('user[bill_date]')
    end
    within('#table_contact_information') do
      assert page.has_no_selector?('user[bill_date]')
    end
  end

  test 'display all operations on user profile' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(saved_user)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: saved_user.id)
    assert find_field('input_first_name').value == saved_user.first_name

    within('.nav-tabs') do
      click_on 'Operations'
    end
    within('#operations_table') do
      assert page.has_content?('user was enrolled')
      assert page.has_content?('Blacklisted user. Reason: Too much spam')
      assert page.has_content?('Blacklisted user. Reason: dont like it')
      assert page.has_content?('Blacklisted user. Reason: testing')
      assert page.has_content?('Communication sent successfully')
    end
    click_on 'Next'
    within('#operations_table') do
      assert page.has_content?('user updated successfully')
      assert page.has_content?('user was recovered')
    end
  end

  test 'see operation history from lastest to newest' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(@saved_user)
    10.times { |time|
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                description: 'user updated succesfully before')
      operation.update_attribute :operation_date, operation.operation_date + (time + 1).minute
    }
    operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                description: 'user updated succesfully last')
    operation.update_attribute :operation_date, operation.operation_date + 11.minute

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations_table') { assert page.has_content?('user updated succesfully last') }
  end

  test 'see operations grouped by billing from lastest to newest' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(@saved_user)
    time = 1
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 100,
                                description: 'member enrolled - 100')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 101,
                                description: 'member enrolled - 101')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 103,
                                description: 'member enrolled - 102')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    4.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 104,
                                description: 'member enrolled - 103')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Operations' }
    within('#dataTableSelect') { select('billing', from: 'operation[operation_type]') }
    within('#operations_table') do
      assert page.has_content?('member enrolled - 101')
      assert page.has_content?('member enrolled - 102')
      assert page.has_content?('member enrolled - 103')
      assert page.has_no_content?('member enrolled - 100')
    end
  end

  test 'see operations grouped by profile from lastest to newest' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(@saved_user)
    time = 1
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 200,
                                description: 'Blacklisted user. Reason: Too much spam - 200')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 201,
                                description: 'Blacklisted user. Reason: Too much spam - 201')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    3.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 202,
                                description: 'Blacklisted user. Reason: Too much spam - 202')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    4.times {
      operation = FactoryBot.create(:operation_billing, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 203,
                                description: 'Blacklisted user. Reason: Too much spam - 203')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Operations' }
    within('#dataTableSelect') { select('profile', from: 'operation[operation_type]') }
    within('#operations_table') do
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 201')
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 202')
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 203')
      assert page.has_no_content?('Blacklisted user. Reason: Too much spam - 200')
    end
  end

  test 'see operations grouped by communication from lastest to newest' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(@saved_user)
    time = 1
    3.times {
      operation = FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 300,
                                description: 'Communication sent - 300')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    sleep 1
    3.times {
      operation = FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 301,
                                description: 'Communication sent - 301')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    sleep 1
    3.times {
      operation = FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 302,
                                description: 'Communication sent - 302')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    sleep 1
    4.times {
      operation = FactoryBot.create(:operation_communication, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 303,
                                description: 'Communication sent - 303')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time += 1
    }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Operations' }
    within('#dataTableSelect') { select('communications', from: 'operation[operation_type]') }
    within('#operations_table') do
      assert page.has_content?('Communication sent - 303')
      assert page.has_content?('Communication sent - 302')
      assert page.has_content?('Communication sent - 301')
      assert page.has_no_content?('Communication sent - 300')
    end
  end

  test 'see operations grouped by others from lastest to newest' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    generate_operations(@saved_user)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    10.times { |time|
      operation = FactoryBot.create(:operation_other, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 1000,
                                description: 'user was updated successfully - 1000')
      operation.update_attribute :operation_date, operation.operation_date + (time + 1).minute
      operation.update_attribute :created_at, operation.created_at + (time + 1).minute
    }
    operation = FactoryBot.create(:operation_other, created_by_id: @admin_agent.id,
                                resource_type: 'user', user_id: @saved_user.id,
                                operation_type: 1000,
                                description: 'user was updated successfully last - 1000')
    operation.update_attribute :operation_date, operation.operation_date + 11.minute
    operation.update_attribute :created_at, operation.created_at + 11.minute
    within('.nav-tabs') { click_on 'Operations' }
    within('#dataTableSelect') { select('others', from: 'operation[operation_type]') }
    within('#operations_table') { assert page.has_content?('user was updated successfully last - 1000') }
  end

  test 'create an user with an expired credit card (if actual month is not january)' do
    unless Time.zone.now.month == 1
      unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
      credit_card = FactoryBot.build(:credit_card_master_card, expire_month: 1, expire_year: Time.zone.now.year)

      visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
      click_link_or_button 'New User'
      fill_in_user(unsaved_user, credit_card)
      assert page.has_content?('expire_year: expired')
    end
  end

  test 'create blank user note' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    click_link_or_button 'Add a note'
    click_link_or_button 'Save note'
    assert_equal current_path, new_user_note_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
  end

  test 'Recover user from sloop with the same credit card' do
    credit_card = FactoryBot.build(:credit_card)
    @saved_user = create_user_by_sloop(@admin_agent, FactoryBot.build(:user), credit_card, nil, @terms_of_membership_with_gateway)
    @saved_user.set_as_canceled!
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    assert find_field('input_first_name').value == @saved_user.first_name

    # reactivate user using sloop form
    assert_difference('User.count', 0) do
      assert_difference('CreditCard.count', 0) do
        create_user_by_sloop(@admin_agent, @saved_user, credit_card, nil, @terms_of_membership_with_gateway)
      end
    end
    @saved_user.reload

    assert_not_equal @saved_user.status, 'lapsed'

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  end

  test 'Create an user without Telephone Type' do
    unsaved_user = FactoryBot.build(:active_user, type_of_phone_number: '', club_id: @club.id)
    FactoryBot.build(:credit_card_master_card)
    create_user(unsaved_user)
    within('#table_contact_information') do
      assert page.has_no_content?('Home')
      assert page.has_no_content?('Mobile')
      assert page.has_no_content?('Other')
    end
  end

  test 'Enroll an user should create membership' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)

    @saved_user = create_user(unsaved_user)
    validate_view_user_base(@saved_user)

    @saved_user.current_membership
  end

  test 'Update Birthday after 12 like a day' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by_email(unsaved_user.email)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_link_or_button 'Edit'
    sleep 1
    page.execute_script("window.jQuery('#user_birth_date').next().click()")
    find('#ui-datepicker-div')
    within('.ui-datepicker-header') do
      find('.ui-datepicker-prev').click
    end
    within('.ui-datepicker-calendar') do
      click_on('13')
    end

    alert_ok_js
    click_link_or_button 'Update User'
    within('#table_contact_information') do
      @saved_user.reload
      assert page.has_content?(@saved_user.birth_date.to_s)
    end
  end

  test 'Check Birthday email -  It is send it by CS at night' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)

    @saved_user = create_user(unsaved_user)

    assert find_field('input_first_name').value == unsaved_user.first_name
    @saved_user = User.find_by_email(unsaved_user.email)
    @saved_user.update_attribute(:birth_date, Time.zone.now)
    excecute_like_server(@club.time_zone) do
      TasksHelpers.send_happy_birthday
    end
    sleep(5)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on 'Communications' }
    within('#communications') do
      find('tr', text: 'Test birthday')
      assert_equal(Communication.last.template_type, 'birthday')
    end

    within('.nav-tabs') { click_on 'Operations' }
    within('#operations_table') do
      assert page.has_content?("Communication 'Test birthday' sent")
      visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    end
  end

  test 'Send Trial email at Day 7' do
    confirm_email_is_sent 7, 'Day 7 - Trial'
  end

  test 'Send News email at Day 35' do
    confirm_email_is_sent 35, 'Day 35 - News'
  end

  test 'Send Deals email at Day 40' do
    confirm_email_is_sent 40, 'Day 40 - Deals'
  end

  test 'Send Local Chapters email at Day 45' do
    confirm_email_is_sent 45, 'Day 45 - Local Chapters'
  end

  test 'Send VIP email at Day 50' do
    confirm_email_is_sent 50, 'Day 50 - VIP'
  end

  test 'Filtering by Communication at Operations tab' do
    setup_email_templates

    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_user = User.find_by_email(unsaved_user.email)
    # billing
    FactoryBot.create(:operation, description: 'enrollment_billing', operation_type: Settings.operation_types.enrollment_billing, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'membership_billing', operation_type: Settings.operation_types.membership_billing, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'full_save', operation_type: Settings.operation_types.full_save, user_id: created_user.id, created_by_id: @admin_agent.id)
    # profile
    FactoryBot.create(:operation, description: 'reset_club_cash', operation_type: Settings.operation_types.reset_club_cash, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'future_cancel', operation_type: Settings.operation_types.future_cancel, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'save_the_sale', operation_type: Settings.operation_types.save_the_sale, user_id: created_user.id, created_by_id: @admin_agent.id)
    # communications
    FactoryBot.create(:operation, description: 'active_email', operation_type: Settings.operation_types.active_email, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'soft_decline_email', operation_type: Settings.operation_types.soft_decline_email, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'pillar_email', operation_type: Settings.operation_types.pillar_email, user_id: created_user.id, created_by_id: @admin_agent.id)
    # fulfillments
    FactoryBot.create(:operation, description: 'from_not_processed_to_in_process', operation_type: Settings.operation_types.from_not_processed_to_in_process, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'from_sent_to_not_processed', operation_type: Settings.operation_types.from_sent_to_not_processed, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'from_sent_to_bad_address', operation_type: Settings.operation_types.from_sent_to_bad_address, user_id: created_user.id, created_by_id: @admin_agent.id)
    # vip
    FactoryBot.create(:operation, description: 'vip_event_registration', operation_type: Settings.operation_types.vip_event_registration, user_id: created_user.id, created_by_id: @admin_agent.id)
    FactoryBot.create(:operation, description: 'vip_event_cancelation', operation_type: Settings.operation_types.vip_event_cancelation, user_id: created_user.id, created_by_id: @admin_agent.id)
    # others
    FactoryBot.create(:operation, description: 'others', operation_type: Settings.operation_types.others, user_id: created_user.id, created_by_id: @admin_agent.id)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: created_user.id)
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { select 'communications', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_content?('active_email')
      assert page.has_content?('soft_decline_email')
      assert page.has_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within('#operations') { select 'billing', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_content?('enrollment_billing')
      assert page.has_content?('membership_billing')
      assert page.has_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within('#operations') { select 'profile', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_content?('reset_club_cash')
      assert page.has_content?('future_cancel')
      assert page.has_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within('#operations') { select 'fulfillments', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_content?('from_not_processed_to_in_process')
      assert page.has_content?('from_sent_to_not_processed')
      assert page.has_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within('#operations') { select 'others', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
      assert page.has_content?('others')
    end
    within('#operations') { select 'vip', from: 'operation[operation_type]' }
    within('#operations') do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_content?('vip_event_registration')
      assert page.has_content?('vip_event_cancelation')
    end
  end

  test 'Update a profile with CC used by another user and Family membership = True' do
    @club_with_family = FactoryBot.create(:simple_club_with_gateway_with_family)
    @partner = @club_with_family.partner
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club_with_family.id)

    unsaved_user = FactoryBot.build(:active_user, club_id: @club_with_family.id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    User.find_by_email(unsaved_user.email)

    visit edit_club_path(@club_with_family.partner.prefix, @club_with_family.id)
    # assert page.has_checked_field?('club_club_cash_enable')

    unsaved_user = FactoryBot.build(:active_user, club_id: @club_with_family.id)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
  end

  test 'Do not allow create users with letters at Credit Card' do
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    FactoryBot.build(:membership_with_enrollment_info)

    visit users_path(partner_prefix: unsaved_user.club.partner.prefix, club_prefix: unsaved_user.club.name)
    click_link_or_button 'New User'

    credit_card = FactoryBot.build(:credit_card_master_card) if credit_card.nil?

    unsaved_user[:type_of_phone_number].blank? ? '' : unsaved_user.type_of_phone_number.capitalize

    within('#table_demographic_information') do
      fill_in 'user[first_name]', with: unsaved_user.first_name
      if unsaved_user.gender == 'Male' || unsaved_user.gender == 'M'
        select('Male', from: 'user[gender]')
      else
        select('Female', from: 'user[gender]')
      end
      fill_in 'user[address]', with: unsaved_user.address
      select_country_and_state(unsaved_user.country)
      fill_in 'user[city]', with: unsaved_user.city
      fill_in 'user[last_name]', with: unsaved_user.last_name
      fill_in 'user[zip]', with: unsaved_user.zip
    end

    within('#table_contact_information') do
      fill_in 'user[phone_country_code]', with: unsaved_user.phone_country_code
      fill_in 'user[phone_area_code]', with: unsaved_user.phone_area_code
      fill_in 'user[phone_local_number]', with: unsaved_user.phone_local_number
      fill_in 'user[email]', with: unsaved_user.email
    end

    within('#table_credit_card') do
      fill_in 'user[credit_card][number]', with: 'creditcardnumber'
      select credit_card.expire_month.to_s, from: 'user[credit_card][expire_month]'
      select credit_card.expire_year.to_s, from: 'user[credit_card][expire_year]'
    end

    click_link_or_button 'Create User'
    assert page.has_content?(I18n.t('error_messages.user_data_invalid'))
    assert page.has_content?('number: is required')
  end

  test 'Do not enroll an user with wrong payment gateway' do
    @club.payment_gateway_configurations.first.update_attribute(:gateway, 'fail')
    unsaved_user  = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card   = FactoryBot.build(:credit_card_master_card, expire_year: Date.today.year + 1)
    fill_in_user(unsaved_user, credit_card, @terms_of_membership_with_gateway.name)
    within('#error_explanation') do
      assert page.has_content?('Member information is invalid.')
      assert page.has_content?('number: An error was encountered while processing your request.')
    end
  end

  test 'Create an user without selecting any' do
    FactoryBot.create(:product, club_id: @club.id, sku: 'PRODUCT_RANDOM')
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
    created_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name, false, '')
    validate_view_user_base(created_user)
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within('#table_enrollment_info') { assert page.has_content?(I18n.t('activerecord.attributes.user.has_no_preferences_saved')) }
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert page.has_content?('Authorization : Transaction Normal - Approved with Stub') }
    assert_equal(Fulfillment.count, 0)
  end
end
