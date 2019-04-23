require 'test_helper'

class RolesTest < ActionDispatch::IntegrationTest
  def setup_admin
    @agent = FactoryBot.create(:confirmed_admin_agent)
    sign_in_as(@agent)
  end

  def setup_agent_no_rol
    @agent = FactoryBot.create(:confirmed_agent)
    @agent.update_attribute(:roles, ' ')
    sign_in_as(@agent)
  end

  def setup_supervisor
    @agent = FactoryBot.create(:confirmed_supervisor_agent)
    sign_in_as(@agent)
  end

  def setup_representative
    @agent = FactoryBot.create(:confirmed_representative_agent)
    @agent.update_attribute(:roles, 'representative')
    sign_in_as(@agent)
  end

  def setup_agency
    @agent = FactoryBot.create(:confirmed_agency_agent)
    @agent.update_attribute(:roles, 'agency')
    sign_in_as(@agent)
  end

  def setup_api
    @agent = FactoryBot.create(:confirmed_api_agent)
    @agent.update_attribute(:roles, 'api')
    sign_in_as(@agent)
  end

  def setup_fulfillment_managment
    @agent = FactoryBot.create(:confirmed_fulfillment_manager_agent)
    @agent.update_attribute(:roles, 'fulfillment_managment')
    sign_in_as(@agent)
  end

  def setup_agent_with_club_role(club, role)
    @agent = FactoryBot.create(:agent)
    club_role = ClubRole.new club_id: club.id
    club_role.agent_id = @agent.id
    club_role.role = role
    club_role.save
    sign_in_as(@agent)
  end

  def setup_user(create_new_user = true)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @communication_type = FactoryBot.create(:communication_type)
    @disposition_type = FactoryBot.create(:disposition_type, club_id: @club.id)

    if create_new_user
      @agent_admin = FactoryBot.create(:confirmed_admin_agent)
      unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)
      excecute_like_server(@club.time_zone) do
        credit_card = FactoryBot.build(:credit_card_master_card)
        enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
        create_user_by_sloop(@agent_admin, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      end
      @saved_user = User.find_by(email: unsaved_user.email)
    end
  end

  test 'can see all clubs with Admin, Supervisor, representative and fulfillment_managment global role' do
    skip('no run now')
    partner = FactoryBot.create(:partner)
    10.times { FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id) }
    %w[confirmed_admin_agent confirmed_supervisor_agent confirmed_representative_agent confirmed_agency_agent confirmed_fulfillment_manager_agent].each do |role|
      agent = FactoryBot.create(role)
      sign_in_as(agent)
      find('#my_clubs').click
      within('#my_clubs_table') do
        Club.all.each { |club| assert page.has_content?(club.name) }
      end
      sign_out
    end
  end

  test 'admin agent assign global roles to agents.' do
    skip('no run now')
    setup_admin
    setup_user false
    @agent_no_role = FactoryBot.create :confirmed_agent
    visit edit_admin_agent_path(@agent_no_role.id)
    choose('admin')
    click_link_or_button 'Update Agent'
    assert page.has_content?('admin')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('api')
    click_link_or_button 'Update Agent'
    assert page.has_content?('api')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('representative')
    click_link_or_button 'Update Agent'
    assert page.has_content?('representative')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('supervisor')
    click_link_or_button 'Update Agent'
    assert page.has_content?('supervisor')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('agency')
    click_link_or_button 'Update Agent'
    assert page.has_content?('agency')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('fulfillment_managment')
    click_link_or_button 'Update Agent'
    assert page.has_content?('fulfillment_managment')
    assert page.has_content?('Agent was successfully updated.')
    click_link_or_button 'Edit'

    choose('landing')
    click_link_or_button 'Update Agent'
    assert page.has_content?('landing')
    assert page.has_content?('Agent was successfully updated.')
  end

  test 'admin agent assign roles by club.' do
    skip('no run now')
    setup_admin
    setup_user false
    @agent_no_role = FactoryBot.create :confirmed_agent
    5.times { FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id) }
    club1 = Club.first
    club2 = Club.second
    club3 = Club.third
    club4 = Club.fourth
    club5 = Club.fifth
    club6 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    club7 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    visit edit_admin_agent_path(@agent_no_role.id)
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('admin', from: '[club_roles_attributes][1][role]')
      select(club1.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('api', from: '[club_roles_attributes][1][role]')
      select(club4.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('supervisor', from: '[club_roles_attributes][1][role]')
      select(club2.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('representative', from: '[club_roles_attributes][1][role]')
      select(club3.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('agency', from: '[club_roles_attributes][1][role]')
      select(club5.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('fulfillment_managment', from: '[club_roles_attributes][1][role]')
      select(club6.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within('.table-condensed') do
      click_link_or_button 'Add'
      select('landing', from: '[club_roles_attributes][1][role]')
      select(club7.name, from: '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    assert page.has_content?('admin for')
    assert page.has_content?('api for')
    assert page.has_content?('supervisor for')
    assert page.has_content?('representative for')
    assert page.has_content?('agency for')
    assert page.has_content?('fulfillment_managment for')
    assert page.has_content?('landing for')
    assert page.has_content?('Agent was successfully updated.')
  end

  test 'Agents that can admin users with role by clubs' do
    skip('no run now')
    setup_agent_no_rol
    partner = FactoryBot.create(:partner)
    first_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    second_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    third_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fourth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fifth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)

    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    visit my_clubs_path
    find('#my_clubs').click
    within('#my_clubs_table') do
      assert page.has_content?(first_club.name.to_s)
      assert page.has_content?(second_club.name.to_s)
      assert page.has_content?(third_club.name.to_s)
      assert page.has_content?(fourth_club.name.to_s)
      assert page.has_content?(fifth_club.name.to_s)
    end

    visit users_path(partner_prefix: partner.prefix, club_prefix: first_club.name)
    assert page.has_selector?('#new_user')

    visit users_path(partner_prefix: partner.prefix, club_prefix: second_club.name)
    assert page.has_selector?('#new_user')

    visit users_path(partner_prefix: partner.prefix, club_prefix: third_club.name)
    assert page.has_content?('401 You are Not Authorized.')
    assert page.has_no_selector?('#new_user')

    visit users_path(partner_prefix: partner.prefix, club_prefix: fourth_club.name)
    assert page.has_no_selector?('#new_user')

    visit users_path(partner_prefix: partner.prefix, club_prefix: fifth_club.name)
    assert page.has_selector?('#new_user')
  end

  test 'Agents that can admin products with role by club' do
    setup_agent_no_rol
    partner = FactoryBot.create(:partner)
    first_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    second_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    third_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fourth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fifth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)

    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    visit my_clubs_path
    find('#my_clubs').click
    within('#my_clubs_table') do
      assert page.has_content?(first_club.name.to_s)
      assert page.has_content?(second_club.name.to_s)
      assert page.has_content?(third_club.name.to_s)
      assert page.has_content?(fourth_club.name.to_s)
      assert page.has_content?(fifth_club.name.to_s)
    end

    visit products_path(partner_prefix: partner.prefix, club_prefix: first_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit products_path(partner_prefix: partner.prefix, club_prefix: second_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit products_path(partner_prefix: partner.prefix, club_prefix: third_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit products_path(partner_prefix: partner.prefix, club_prefix: fourth_club.name)
    assert page.has_no_content?('401 You are Not Authorized.')
    assert page.has_content?('Show')
    visit products_path(partner_prefix: partner.prefix, club_prefix: fourth_club.name)
    click_link_or_button 'Show'
    assert page.has_no_content?('401 You are Not Authorized.')

    visit products_path(partner_prefix: partner.prefix, club_prefix: fifth_club.name)
    assert page.has_no_content?('401 You are Not Authorized.')
    assert page.has_content?('Show')
    visit products_path(partner_prefix: partner.prefix, club_prefix: fifth_club.name)
    click_link_or_button 'Show'
    assert page.has_no_content?('401 You are Not Authorized.')
  end

  test 'Agents that can admin fulfillments with role by club' do
    setup_agent_no_rol
    partner = FactoryBot.create(:partner)
    first_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    second_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    third_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fourth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)
    fifth_club = FactoryBot.create(:simple_club_with_gateway, partner_id: partner.id)

    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    visit my_clubs_path
    find('#my_clubs').click
    within('#my_clubs_table') do
      assert page.has_content?(first_club.name.to_s)
      assert page.has_content?(second_club.name.to_s)
      assert page.has_content?(third_club.name.to_s)
      assert page.has_content?(fourth_club.name.to_s)
      assert page.has_content?(fifth_club.name.to_s)
    end

    visit fulfillments_index_path(partner_prefix: partner.prefix, club_prefix: first_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit fulfillments_index_path(partner_prefix: partner.prefix, club_prefix: second_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit fulfillments_index_path(partner_prefix: partner.prefix, club_prefix: third_club.name)
    assert page.has_content?('401 You are Not Authorized.')

    visit fulfillments_index_path(partner_prefix: partner.prefix, club_prefix: fourth_club.name)
    assert page.has_no_content?('401 You are Not Authorized.')

    visit fulfillments_index_path(partner_prefix: partner.prefix, club_prefix: fifth_club.name)
    assert page.has_no_content?('401 You are Not Authorized.')
  end

  test 'club role admin available actions' do
    setup_user false
    setup_agent_with_club_role(@club, 'admin')
    unsaved_user = FactoryBot.build(:user_with_api, club_id: @club.id)

    within('#my_clubs_table') do
      assert page.has_selector?('#users')
      assert page.has_selector?('#products')
      assert page.has_selector?('#fulfillments')
      assert page.has_selector?('#fulfillment_files')
      assert page.has_content?('Suspected Fulfillments')
      assert page.has_content?('Campaigns')
      assert page.has_content?('Campaign Days')
      assert page.has_content?('Disposition Types')
    end

    @saved_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name)
    credit_card = FactoryBot.create(:credit_card_american_express, user_id: @saved_user.id, active: false)
    validate_view_user_base(@saved_user)

    assert find(:xpath, "//a[@id='edit']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='save_the_sale']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='blacklist_btn']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_user_note']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='cancel']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_credit_card']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//input[@id='activate_credit_card_button']")[:class].exclude? 'disabled' }
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now

    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

    @saved_user.bill_membership
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert find(:xpath, "//a[@id='refund']")[:class].exclude? 'disabled' }

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//a[@id='destroy']")[:class].exclude? 'disabled' }

    visit products_path(@partner.prefix, @club.name)
    within('#products_table') do
      assert find(:xpath, "//a[@id='show']")[:class].exclude? 'disabled'
    end

    visit fulfillments_index_path(@partner.prefix, @club.name)
    within('#fulfillments_table') { assert find(:xpath, "//input[@id='make_report']")[:class].exclude? 'disabled' }
  end

  test 'club role representative available actions' do
    setup_user false
    setup_agent_with_club_role(@club, 'representative')
    unsaved_user = FactoryBot.build(:user_with_api, club_id: @club.id)

    within('#my_clubs_table') do
      assert page.has_selector?('#users')
      assert page.has_no_selector?('#products')
      assert page.has_no_selector?('#fulfillments')
      assert page.has_no_selector?('#fulfillment_files')
      assert page.has_no_content?('Suspected Fulfillments')
      assert page.has_no_content?('Campaigns')
      assert page.has_no_content?('Campaign Days')
      assert page.has_no_content?('Disposition Types')
    end

    @saved_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name)
    credit_card = FactoryBot.create(:credit_card_american_express, user_id: @saved_user.id, active: false)
    validate_view_user_base(@saved_user)

    assert find(:xpath, "//a[@id='edit']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='save_the_sale']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='blacklist_btn']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_user_note']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='cancel']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_credit_card']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:class].include? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//input[@id='activate_credit_card_button']")[:class].exclude? 'disabled' }
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    @saved_user.bill_membership
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert find(:xpath, "//a[@id='refund']")[:class].exclude? 'disabled' }

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }
  end

  test 'club role supervisor available actions' do
    setup_user false
    setup_agent_with_club_role(@club, 'supervisor')
    unsaved_user = FactoryBot.build(:user_with_api, club_id: @club.id)

    within('#my_clubs_table') do
      assert page.has_selector?('#users')
      assert page.has_no_selector?('#products')
      assert page.has_no_selector?('#fulfillments')
      assert page.has_no_selector?('#fulfillment_files')
      assert page.has_content?('Suspected Fulfillments')
      assert page.has_no_content?('Campaigns')
      assert page.has_no_content?('Campaign Days')
      assert page.has_no_content?('Disposition Types')
    end

    @saved_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name)
    credit_card = FactoryBot.create(:credit_card_american_express, user_id: @saved_user.id, active: false)
    validate_view_user_base(@saved_user)

    assert find(:xpath, "//a[@id='edit']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='save_the_sale']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='blacklist_btn']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_user_note']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='cancel']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_credit_card']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//input[@id='activate_credit_card_button']")[:class].exclude? 'disabled' }
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    @saved_user.bill_membership
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert find(:xpath, "//a[@id='refund']")[:class].exclude? 'disabled' }

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//a[@id='destroy']")[:class].exclude? 'disabled' }
  end

  test 'club role agency available actions' do
    skip('no run now')
    setup_user
    setup_agent_with_club_role(@club, 'agency')
    credit_card = FactoryBot.create(:credit_card_american_express, active: false, user_id: @saved_user.id)

    within('#my_clubs_table') do
      assert page.has_selector?('#users')
      assert page.has_selector?('#products')
      assert page.has_selector?('#fulfillments')
      assert page.has_selector?('#fulfillment_files')
      assert page.has_no_content?('Suspected Fulfillments')
      assert page.has_no_content?('Campaigns')
      assert page.has_no_content?('Campaign Days')
      assert page.has_no_content?('Disposition Types')
    end

    visit users_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    assert page.has_no_selector?('#new_user')

    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)

    assert find(:xpath, "//a[@id='edit']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='save_the_sale']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='blacklist_btn']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_user_note']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='cancel']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='add_credit_card']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:class].include? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//input[@id='activate_credit_card_button']")[:class].include? 'disabled' }

    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert find(:xpath, "//a[@id='refund']")[:class].include? 'disabled' }

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].include? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    visit products_path(@partner.prefix, @club.name)
    within('#products_table') do
      assert find(:xpath, "//a[@id='show']")[:class].exclude? 'disabled'
    end

    visit fulfillments_index_path(@partner.prefix, @club.name)
    within('#fulfillments_table') { assert find(:xpath, "//input[@id='make_report']")[:class].exclude? 'disabled' }
  end

  test 'club role fulfillment_managment available actions' do
    setup_user false
    setup_agent_with_club_role(@club, 'fulfillment_managment')
    unsaved_user = FactoryBot.build(:user_with_api, club_id: @club.id)

    within('#my_clubs_table') do
      assert page.has_selector?('#users')
      assert page.has_selector?('#products')
      assert page.has_selector?('#fulfillments')
      assert page.has_selector?('#fulfillment_files')
      assert page.has_content?('Suspected Fulfillments')
      assert page.has_no_content?('Campaigns')
      assert page.has_no_content?('Campaign Days')
      assert page.has_no_content?('Disposition Types')
    end

    @saved_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name)
    credit_card = FactoryBot.create(:credit_card_american_express, user_id: @saved_user.id, active: false)
    validate_view_user_base(@saved_user)

    assert find(:xpath, "//a[@id='edit']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='save_the_sale']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='blacklist_btn']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_user_note']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='cancel']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='add_credit_card']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:class].exclude? 'disabled'
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:class].include? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert find(:xpath, "//input[@id='activate_credit_card_button']")[:class].exclude? 'disabled' }
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    @saved_user.bill_membership
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') { assert find(:xpath, "//a[@id='refund']")[:class].exclude? 'disabled' }

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].exclude? 'disabled'
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') { assert page.has_no_selector?('#destroy') }

    visit products_path(@partner.prefix, @club.name)
    within('#products_table') do
      assert find(:xpath, "//a[@id='show']")[:class].exclude? 'disabled'
    end

    visit fulfillments_index_path(@partner.prefix, @club.name)
    within('#fulfillments_table') { assert find(:xpath, "//input[@id='make_report']")[:class].exclude? 'disabled' }
  end
end
