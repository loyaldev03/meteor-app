require 'test_helper'

class UsersSearchTest < ActionDispatch::IntegrationTest
  setup do
    unstubs_elasticsearch_index
    User.index.delete
    User.create_elasticsearch_index
    @transactions_table_empty_text    = 'No data available in table'
    @operations_table_empty_text      = 'No data available in table'
    @fulfillments_table_empty_text    = 'No fulfillments were found'
    @communication_table_empty_text   = 'No communications were found'
    @default_state                    = 'Alabama' # when we select options we do it by option text not by value ?
    @admin_agent                      = FactoryBot.create(:confirmed_admin_agent)
    @partner                          = FactoryBot.create(:partner)
    @club                             = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    Time.zone                         = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @communication_type               = FactoryBot.create(:communication_type)
    @disposition_type                 = FactoryBot.create(:disposition_type, club_id: @club.id)
    sign_in_as(@admin_agent)
  end

  def setup_search(create_new_users = true)
    if create_new_users
      10.times { create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, created_by: @admin_agent) }
      10.times { create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, created_by: @admin_agent) }
      10.times { create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, created_by: @admin_agent) }
    end
    sleep 1
    User.index.import User.all
    @search_user = User.first
    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
  end

  def search_user(fields_selector, user, country = nil, validate = true)
    User.index.import User.all
    sleep 1

    visit users_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name)
    fields_selector.each do |field, value|
      next if value.nil?

      if ['user[status]'].include? field
        select value, from: field
      else
        fill_in field, with: value
      end
    end
    select_country_and_state(user.country) if country
    within('#index_search_form') { click_on 'Search' }
    if validate
      within('#users') do
        assert page.has_content?(user.status)
        assert page.has_content?(user.id.to_s)
        assert page.has_content?(user.full_name)
        assert page.has_content?(user.full_address)
        assert page.has_content?(user.email)
        assert page.has_content?(user.external_id) if user.external_id.present?
      end
    end
  end

  test 'search user with empty form' do
    setup_search
    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    within('#index_search_form') do
      alert_ok_js
      click_link_or_button 'Search'
    end
  end

  test 'search user by user id' do
    setup_search
    search_user({ 'user[id]' => @search_user.id }, @search_user)
  end

  test 'search user by date billing information' do
    unsaved_user  = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card   = FactoryBot.build(:credit_card_master_card, expire_year: Date.today.year + 1)
    @saved_user   = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, nil, @terms_of_membership_with_gateway, false)
    @saved_user.active_credit_card
    User.index.import User.all

    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    transaction = Transaction.first
    date_time   = transaction.created_at.utc
    select_from_datepicker('user_transaction_start_date', date_time)
    find('#submit_button').click
    assert page.find('#table_user_search_result').has_content?(@saved_user.status)
    assert page.find('#table_user_search_result').has_content?(@saved_user.id.to_s)
    assert page.find('#table_user_search_result').has_content?(@saved_user.email)
    assert page.find('#table_user_search_result').has_content?(@saved_user.full_name)
    assert page.find('#table_user_search_result').has_content?(@saved_user.full_address)
  end

  test 'search user by amount billing information' do
    unsaved_user  = FactoryBot.build(:active_user, club_id: @club.id)
    credit_card   = FactoryBot.build(:credit_card_master_card, expire_year: Date.today.year + 1)
    @saved_user   = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, nil, @terms_of_membership_with_gateway, false)
    @saved_user.active_credit_card
    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    search_user({ 'user[transaction_amount]' => 0.50 }, @saved_user)
  end

  test 'search user by phone' do
    setup_search
    @search_user.update_attribute :phone_country_code, '1'
    @search_user.update_attribute :phone_area_code, '321'
    @search_user.update_attribute :phone_local_number, '1234567'
    search_user({ 'user[phone_number]' => '1-321-1234567' }, @search_user)
  end

  test 'search user by first_name' do
    setup_search
    search_user({ 'user[first_name]' => @search_user.first_name }, @search_user)
    @search_user.update_attribute :first_name, 'Darrel Barry'
    search_user({ 'user[first_name]' => 'Bar Dar' }, @search_user)
  end

  # Search user with duplicated letters at Last Name
  test 'search by last name' do
    setup_search false
    2.times { create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, created_by: @admin_agent) }
    2.times { create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, created_by: @admin_agent) }
    2.times { create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, created_by: @admin_agent) }
    create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, created_by: @admin_agent)
    User.index.import User.all

    active_user           = User.find_by status: 'active'
    provisional_user      = User.find_by status: 'provisional'
    lapsed_user           = User.find_by status: 'lapsed'
    duplicated_name_user  = User.last
    duplicated_name_user.update_attribute(:last_name, 'Elwood')
    search_user({ 'user[last_name]' => 'Elwood' }, duplicated_name_user)
    search_user({ 'user[last_name]' => active_user.last_name }, active_user)
    within('#users') do
      assert page.has_css?('tr td.btn-success')
    end
    search_user({ 'user[last_name]' => provisional_user.last_name }, provisional_user)
    within('#users') do
      assert page.has_css?('tr td.btn-warning')
    end
    search_user({ 'user[last_name]' => lapsed_user.last_name }, lapsed_user)
    within('#users') do
      assert page.has_css?('tr td.btn-danger')
    end
  end

  test 'search user by email' do
    setup_search
    search_user({ 'user[email]' => @search_user.email.to_s }, @search_user)
    search_user({ 'user[email]' => "#{@search_user.email.split('@').first}*" }, @search_user)
  end

  test 'search user by city' do
    setup_search
    search_user({ 'user[city]' => @search_user.city.to_s }, @search_user)
  end

  test 'search user by state' do
    setup_search
    user_to_search = User.order('id').last
    search_user({}, user_to_search, user_to_search.country)
  end

  test 'search user by user zip' do
    setup_search
    search_user({ 'user[zip]' => @search_user.zip.to_i }, @search_user)
  end

  test 'search by last digits' do
    setup_search
    cc_last_digits = 8965
    @search_user.active_credit_card.update_attribute :last_digits, cc_last_digits

    search_user({ 'user[cc_last_digits]' => '8965' }, @search_user)
  end

  test 'search by last status' do
    setup_search
    %w[provisional active lapsed].each do |status|
      user_to_search = User.where(status: status).last
      search_user({ 'user[status]' => status }, user_to_search)
      within('#users') do
        find('tr', text: user_to_search.full_name)
      end
    end
  end

  test 'search user by pagination' do
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, :membership_with_enrollment_info, {}, created_by: @admin_agent)
    20.times do
      create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, created_by: @admin_agent)
    end
    30.times do
      create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, created_by: @admin_agent)
    end
    30.times do
      create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, created_by: @admin_agent)
    end
    User.index.import User.all

    visit users_path(partner_prefix: @club.partner.prefix, club_prefix: @club.name)
    fill_in 'user[email]', with: 'a'
    within('#index_search_form') do
      click_on 'Search'
    end
    within('.pagination') do
      assert page.has_content?('1')
      assert page.has_content?('2')
      assert page.has_content?('3')
      assert page.has_content?('4')
      assert page.has_content?('Next')
    end
    within('#users') do
      begin
        assert assert page.has_no_content?(User.where('club_id = ?', @club.id).order('id DESC').last.full_name)
        assert page.has_content?(User.where('club_id = ?', @club.id).order('id DESC').first.full_name)
      end
      click_on('2')
      sleep 2
      begin
        assert assert page.has_no_content?(User.where('club_id = ?', @club.id).order('id DESC').last.full_name)
        assert assert page.has_content?(User.where('club_id = ?', @club.id).order('id DESC')[21].full_name)
      end
      click_on('5')
      sleep 2
      begin
        assert page.has_content?(User.where('club_id = ?', @club.id).order('id DESC').last.full_name)
      end
    end
  end

  test 'display user' do
    setup_search
    search_user({ 'user[id]' => @search_user.id.to_i }, @search_user)
    page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")

    validate_view_user_base(@search_user, @search_user.status)

    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') { assert page.has_content?(@operations_table_empty_text) }

    active_credit_card = @search_user.active_credit_card
    within('.nav-tabs') { click_on('Credit Cards') }
    within('#credit_cards') do
      assert page.has_content?(active_credit_card.number.to_i)
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    end

    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table') { assert page.has_content?(@transactions_table_empty_text) }
    within('.nav-tabs') { click_on('Fulfillments') }
    within('#fulfillments') { assert page.has_content?(@fulfillments_table_empty_text) }
    within('.nav-tabs') { click_on('Communications') }
    within('#communications') { assert page.has_content?(@communication_table_empty_text) }
  end

  test 'search by multiple values, trimming and also with invalid characters' do
    user_to_search = @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    search_user({ 'user[id]' => user_to_search.id.to_i, 'user[first_name]' => user_to_search.first_name,
                 'user[last_name]' => user_to_search.last_name, 'user[email]' => user_to_search.email,
                 'user[city]' => user_to_search.city, 'user[zip]' => user_to_search.zip }, user_to_search, user_to_search.country)
    search_user({ 'user[id]' => user_to_search.id.to_i, 'user[first_name]' => "  #{user_to_search.first_name}  ",
                 'user[last_name]' => user_to_search.last_name.to_s, 'user[email]' => "  #{user_to_search.email}  ",
                 'user[city]' => user_to_search.city.to_s, 'user[zip]' => "  #{user_to_search.zip}  " }, user_to_search, user_to_search.country)
  end

  test 'search user that does not exist' do
    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    within('#personal_details') do
      fill_in 'user[first_name]', with: 'Random text'
    end
    within('#index_search_form') do
      click_link_or_button 'Search'
    end
    within('#users') do
      assert page.has_content?('No records were found.')
    end
  end

  test "should show status with 'Blisted' on search results, when user is blacklisted." do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    FactoryBot.create(:member_cancel_reason, club_id: 1)
    @saved_user.set_as_canceled!
    @saved_user.update_attribute(:blacklisted, true)
    search_user({ 'user[id]' => @saved_user.id.to_i }, @saved_user)
    within('#users') do
      assert page.has_content?('- Blisted')
    end
  end
end
