require 'test_helper'

class UsersProfileEditTest < ActionDispatch::IntegrationTest
  setup do
    @communication_type = FactoryBot.create(:communication_type)
  end

  def setup_user(create_new_user = true)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)

    @partner = @club.partner
    Time.zone = @club.time_zone
    @disposition_type = FactoryBot.create(:disposition_type, club_id: @club.id)

    if create_new_user
      active_merchant_stub
      unsaved_user    = FactoryBot.build(:provisional_user_with_cc, club_id: @club.id)
      credit_card     = FactoryBot.build(:credit_card)
      membership_info = FactoryBot.build(:membership_with_enrollment_info_without_enrollment_amount)

      @terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)
      @saved_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, membership_info, @terms_of_membership_with_gateway)
    end
    sign_in_as(@admin_agent)
  end

  def set_as_unreachable_user(user, reason)
    visit user_set_unreachable_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#unreachable_table') { select(reason, from: 'reason') }
    click_link_or_button 'Set wrong phone number'
    confirm_ok_js
  end

  def add_credit_card(user_id, credit_card, subscription_plan = nil)
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    visit new_credit_card_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: user_id)
    fill_in 'credit_card[number]', with: credit_card.number
    select credit_card.expire_month.to_s, from: 'credit_card[expire_month]'
    select credit_card.expire_year.to_s, from: 'credit_card[expire_year]'
    select subscription_plan, from: 'terms_of_membership_id' if subscription_plan
    click_on 'Save credit card'
  end

  def active_merchant_stub
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true)
  end

  ###########################################################
  # TESTS
  ###########################################################

  test 'edit user' do
    setup_user
    visit edit_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('#table_demographic_information') do
      assert find_field('user[first_name]').value == @saved_user.first_name
      assert find_field('user[last_name]').value == @saved_user.last_name
      assert find_field('user[city]').value == @saved_user.city
      assert find_field('user[address]').value == @saved_user.address
      assert find_field('user[zip]').value == @saved_user.zip
      assert find_field('user[state]').value == @saved_user.state
      assert find_field('user[gender]').value == @saved_user.gender
      assert find_field('user[country]').value == @saved_user.country
    end

    within('#table_contact_information') do
      assert find_field('user[email]').value == @saved_user.email
      assert find_field('user[phone_country_code]').value == @saved_user.phone_country_code.to_s
      assert find_field('user[phone_area_code]').value == @saved_user.phone_area_code.to_s
      assert find_field('user[phone_local_number]').value == @saved_user.phone_local_number.to_s
      assert find_field('user[type_of_phone_number]').value == @saved_user.type_of_phone_number.to_s
    end
    alert_ok_js
    assert_difference('User.count', 0) do
      click_link_or_button 'Update User'
    end
    assert find_field('input_first_name').value == @saved_user.first_name
  end

  test 'set undeliverable address' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    set_as_undeliverable_user(@saved_user, 'reason')
    confirm_ok_js
  end

  test 'add new credit_card and active old credit_Card' do
    setup_user
    old_active_credit_card  = @saved_user.active_credit_card
    new_cc                  = FactoryBot.build(:credit_card, number: '378282246310005', expire_month: Time.new.month, expire_year: Time.new.year + 10)
    last_digits             = new_cc.last_digits
    add_credit_card(@saved_user.id, new_cc)
    cc_saved = @saved_user.reload.active_credit_card
    assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated")

    within('#table_active_credit_card') do
      assert page.has_content?(last_digits)
      assert page.has_content?("#{cc_saved.expire_month} / #{cc_saved.expire_year}")
    end
    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') { assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated") }

    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') do
      within('.ligthgreen') do
        assert page.has_content?(last_digits)
        assert page.has_content?("#{cc_saved.expire_month} / #{cc_saved.expire_year}")
        assert page.has_content?('active')
      end
    end
    within('#credit_cards') { click_link_or_button 'Activate' }
    confirm_ok_js
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') do
      within('.ligthgreen') do
        assert page.has_content?("#{old_active_credit_card.last_digits}")
        assert page.has_content?("#{old_active_credit_card.expire_month} / #{old_active_credit_card.expire_year}")
      end
    end
  end

  test 'add new credit_card and new Subscription Plan' do
    setup_user
    new_cc = FactoryBot.build(:credit_card, number: '378282246310005', expire_month: Time.new.month, expire_year: Time.new.year + 10)
    new_terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)

    last_digits = new_cc.last_digits
    add_credit_card(@saved_user.id, new_cc, new_terms_of_membership_with_gateway.name)
    cc_saved = @saved_user.reload.active_credit_card
    assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated.Member enrolled successfully $0.0 on TOM(#{new_terms_of_membership_with_gateway.id}) -#{new_terms_of_membership_with_gateway.name}-")

    within('#table_active_credit_card') do
      assert page.has_content?(last_digits)
      assert page.has_content?("#{cc_saved.expire_month} / #{cc_saved.expire_year}")
    end

    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') do
      assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated")
      assert page.has_content?('Rollback to previous Membership')
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{new_terms_of_membership_with_gateway.id}) -#{new_terms_of_membership_with_gateway.name}-")
    end
  end

  test 'edit a note and click on link' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    set_as_undeliverable_user(@saved_user, 'reason')
    confirm_ok_js
    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') { first('.icon-zoom-in').click }

    text_note = 'text note 123456789'
    fill_in 'operation_notes', with: text_note

    assert_difference('Operation.count') do
      click_on 'Save operation'
    end

    assert page.has_content?('Edited operation note')
    within('.alert') do
      within('p') do
        find('a').click
      end
    end
    assert find_field('operation_notes').value == text_note

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') do
      assert page.has_content?('Edited operation note')
      assert page.has_content?(@saved_user.operations.first.id)
    end
  end

  test 'change unreachable address to undeliverable when changeing address, city or zip' do
    setup_user
    { 'user[address]' => 'random address', 'user[city]' => 'random city', 'user[zip]' => '98765' }.each do |field, value|
      set_as_undeliverable_user(@saved_user, 'reason')

      click_link_or_button 'Edit'
      within('#table_demographic_information') { fill_in field, with: value }
      alert_ok_js
      click_link_or_button 'Update User'
      sleep 5
      within('#table_demographic_information') { assert !page.has_css?('tr.yellow') }
      @saved_user.reload
      assert_nil @saved_user.wrong_phone_number
    end
  end

  test 'change unreachable address to undeliverable when changing state or country and state' do
    setup_user
    set_as_undeliverable_user(@saved_user, 'reason')

    click_link_or_button 'Edit'
    within('#table_demographic_information') do
      within('#states_td') { select('Colorado', from: 'user[state]') }
    end
    alert_ok_js
    click_link_or_button 'Update User'
    within('#table_demographic_information') do
      assert !page.has_css?('tr.yellow')
    end
    @saved_user.reload
    assert_nil @saved_user.wrong_phone_number

    set_as_undeliverable_user(@saved_user, 'reason')
    click_link_or_button 'Edit'
    within('#table_demographic_information') do
      select('Canada', from: 'user[country]')
      within('#states_td') { select('Ontario', from: 'user[state]') }
    end
    alert_ok_js
    click_link_or_button 'Update User'
    within('#table_demographic_information') do
      assert !page.has_css?('tr.yellow')
    end
    @saved_user.reload
    assert_nil @saved_user.wrong_phone_number
  end

  test 'change unreachable phone number to reachable by changeing phone' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    # By changing phone_country_number

    set_as_unreachable_user(@saved_user, 'Unreachable')

    click_link_or_button 'Edit'
    within('#table_contact_information') { fill_in 'user[phone_country_code]', with: '987' }
    alert_ok_js
    click_link_or_button 'Update User'
    sleep 10
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#table_contact_information') { assert !page.has_css?('tr.yellow') }
    @saved_user.reload

    assert_nil @saved_user.wrong_phone_number
    # By changing phone_area_code
    set_as_unreachable_user(@saved_user, 'Unreachable')

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    click_link_or_button 'Edit'
    within('#table_contact_information') do
      fill_in 'user[phone_area_code]', with: '987'
    end
    alert_ok_js
    click_link_or_button 'Update User'

    within('#table_contact_information') { assert !page.has_css?('tr.yellow') }
    @saved_user.reload
    assert_nil @saved_user.wrong_phone_number

    # By changing phone_local_number
    set_as_unreachable_user(@saved_user, 'Unreachable')

    within('#table_contact_information') { assert page.has_css?('tr.yellow') }
    @saved_user.reload
    assert_equal @saved_user.wrong_phone_number, 'Unreachable'

    click_link_or_button 'Edit'
    within('#table_contact_information') { fill_in 'user[phone_local_number]', with: '9876' }
    alert_ok_js
    click_link_or_button 'Update User'

    within('#table_contact_information') { assert !page.has_css?('tr.yellow') }
    @saved_user.reload
    assert_nil @saved_user.wrong_phone_number
  end

  test "edit user's type of phone number" do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('#table_contact_information') { assert page.has_content?(@saved_user.type_of_phone_number.capitalize) }

    click_link_or_button 'Edit'

    within('#table_contact_information') { select('Mobile', from: 'user[type_of_phone_number]') }
    alert_ok_js
    click_link_or_button 'Update User'
    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    within('#table_contact_information') { assert page.has_content?(@saved_user.type_of_phone_number.capitalize) }
  end

  test 'Update external id' do
    setup_user(false)
    @club_external_id = FactoryBot.create(:simple_club_with_require_external_id, partner_id: @partner.id)
    @terms_of_membership_with_external_id = FactoryBot.create(:terms_of_membership_with_gateway_and_external_id, club_id: @club_external_id.id)
    @user_with_external_id = create_active_user(@terms_of_membership_with_external_id, :active_user_with_external_id, nil, {}, created_by: @admin_agent)

    visit edit_user_path(partner_prefix: @user_with_external_id.club.partner.prefix, club_prefix: @user_with_external_id.club.name, user_prefix: @user_with_external_id.id)

    within('#external_id') { fill_in 'user[external_id]', with: '987654321' }
    alert_ok_js
    click_link_or_button 'Update User'

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club_external_id.name, user_prefix: @user_with_external_id.id)
    assert find_field('input_first_name').value == @user_with_external_id.first_name

    @user_with_external_id.reload
    assert_equal @user_with_external_id.external_id, '987654321'
    within('#td_mi_external_id') { assert page.has_content?(@user_with_external_id.external_id) }
  end

  test 'change user gender from male to female and then to male again.' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    assert find_field('input_gender').value == (@saved_user.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within('#table_demographic_information') { select('Female', from: 'user[gender]') }
    alert_ok_js
    click_link_or_button 'Update User'

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    assert find_field('input_gender').value == 'Female'
    assert_equal @saved_user.gender, 'F'

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_gender').value == (@saved_user.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within('#table_demographic_information') { select('Male', from: 'user[gender]') }
    alert_ok_js
    click_link_or_button 'Update User'
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    assert find_field('input_gender').value == 'Male'
    assert_equal @saved_user.gender, 'M'
  end

  test 'Should not show destroy button on credit card when this one is the last one' do
    setup_user

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    @saved_user.set_as_canceled!
    @saved_user.update_attribute(:blacklisted, true)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    @saved_user.update_attribute(:blacklisted, false)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }
  end

  test 'Delete credit card only when user is lapsed and is not blacklisted (and credit card is not the last one)' do
    setup_user
    second_credit_card = FactoryBot.create(:credit_card_american_express, user_id: @saved_user.id, active: false)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    @saved_user.update_attribute(:status, 'provisional')
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    @saved_user.set_as_canceled!
    @saved_user.update_attribute(:blacklisted, true)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    @saved_user.update_attribute(:blacklisted, false)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') do
      click_on('Credit Cards')
    end
    sleep 2
    within('#credit_cards') do
      assert page.has_selector?('#destroy')
      click_link_or_button('Destroy')
      confirm_ok_js
    end
    assert page.has_content?("Credit Card #{second_credit_card.last_digits} was successfully destroyed")
  end

  test 'See operations on CS' do
    setup_user(true)
    active_merchant_stub
    @saved_user.current_membership.join_date = Time.zone.now - 3.day

    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2)
    bill_user(@saved_user)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table_wrapper') do
      assert page.has_selector?('#refund')
      click_link_or_button('Refund')
    end
    fill_in 'refunded_amount', with: final_amount
    click_link_or_button 'Refund'
    page.has_content?('This transaction has been approved')

    visit user_save_the_sale_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, transaction_id: Transaction.last.id)
    click_on 'Full save'
    assert page.has_content?('Full save done')

    within('.nav-tabs') { click_on('Operations') }
    select '50', from: 'operations_table_length'
    within('#operations_table') do
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-")
      assert page.has_content?('Assigned fulfillment upon enrollment.')
      assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}")
      assert page.has_content?("Refund success $#{final_amount.to_f}")
      assert page.has_content?('Full save done')
    end
  end

  test 'Sorting transaction table' do
    setup_user
    12.times do |index|
      FactoryBot.create(:transaction, user_id: @saved_user.id, transaction_type: 'sale', response_result: index, response_transaction_id: index, gateway: 'mes')
      sleep 0.25
    end
    first_transaction = Transaction.find_by response_result: 0
    last_transaction = Transaction.find_by response_result: 11
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table') do
      assert page.has_content?(I18n.l(last_transaction.created_at, :format => :dashed))
      find('#th_date').click
      assert page.has_content?(I18n.l(first_transaction.created_at, :format => :dashed))
    end
  end

  test 'Sorting membership table' do
    setup_user

    11.times { @saved_user.bill_membership }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

    within('.nav-tabs') { click_on('Memberships') }
    within('#memberships_table') do
      assert page.has_content?(Membership.last.id.to_s)
      find('#th_id').click
      find('#th_id').click
      assert page.has_content?(Membership.first.id.to_s)
    end
  end

  test 'Update an user with CC blacklisted inside the same Club' do
    setup_user true
    @saved_user.active_credit_card.update_attribute :blacklisted, true

    unsaved_user    = FactoryBot.build(:provisional_user_with_cc, club_id: @club.id, email: 'testing@withthisemail.com')
    credit_card     = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info_without_enrollment_amount)
    @terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)
    new_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)

    add_credit_card(new_user.id, FactoryBot.build(:credit_card))
    assert page.has_content?("There was an error with your credit card information. Please call member services at: #{@club.cs_phone_number}.")
    assert page.has_content?('{:number=>"Credit card is blacklisted"}')
  end

  test 'Mark an unmark an user as testing account' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    click_link_or_button I18n.t('buttons.mark_as_testing_account')
    assert page.has_content? 'This user is set as testing account.'
    assert @saved_user.reload.testing_account
    click_link_or_button I18n.t('buttons.unmark_as_testing_account')
    assert page.has_content? 'User is no longer set as testing account.'
    assert !@saved_user.reload.testing_account
  end
end
