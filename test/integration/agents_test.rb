require 'test_helper'

class AgentsTest < ActionDispatch::IntegrationTest
  def setup_environment
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    FactoryBot.create(:simple_club_with_gateway)
    sign_in_as(@admin_agent)
  end

  def fill_in_form(agent)
    fill_in 'agent[email]', with: agent.email
    fill_in 'agent[username]', with: agent.username
    fill_in 'agent[password]', with: agent.password
    fill_in 'agent[password_confirmation]', with: agent.password_confirmation
  end

  def create_agent_try_to_recover_it(global_role = true)
    confirmed_agent = FactoryBot.create(:confirmed_agent)
    assert_equal 1, Agent.where(email: confirmed_agent.email).count

    visit new_admin_agent_path
    fill_in 'agent[email]', with: confirmed_agent.email
    fill_in 'agent[username]', with: 'newpassword'
    fill_in 'agent[password]', with: 'newpassword'
    fill_in 'agent[password_confirmation]', with: 'newpassword'

    if global_role
      choose('agent_roles_admin')
    else
      within('#new_agent') do
        click_on 'Add'
        select('admin', from: '[club_roles_attributes][1][role]')
      end
    end
    assert_difference('Agent.count', 0) do
      click_link_or_button 'Create Agent'
    end

    assert page.has_content?('has already been taken')
    assert_equal 1, Agent.where(email: confirmed_agent.email).count
  end

  def create_agent_destroy_it_and_recover_it(destination_global_role, source_global_role)
    if source_global_role
      confirmed_agent = FactoryBot.create(:confirmed_admin_agent)
    else
      prepare_agents_with_club_roles
      confirmed_agent = @agent_club_role_admin
    end
    assert_equal 1, Agent.where(email: confirmed_agent.email).count
    confirmed_agent.destroy
    assert_equal 0, Agent.where(email: confirmed_agent.email).count

    visit new_admin_agent_path
    fill_in 'agent[email]', with: confirmed_agent.email
    fill_in 'agent[username]', with: 'newpassword'
    fill_in 'agent[password]', with: 'newpassword'
    fill_in 'agent[password_confirmation]', with: 'newpassword'
    if destination_global_role
      choose('agent_roles_admin')
    else
      within('#new_agent') do
        click_on 'Add'
        select('admin', from: '[club_roles_attributes][1][role]')
      end
    end
    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    assert page.has_content?('Agent was successfully created')
    assert_equal 1, Agent.where(email: confirmed_agent.email).count

    if destination_global_role
      assert page.has_xpath?('//ul[@id="global_role_list"]/li')
      assert page.has_no_xpath?('//ul[@id="club_role_list"]/li')
    else
      assert page.has_no_xpath?('//ul[@id="global_role_list"]/li')
      assert page.has_xpath?('//ul[@id="club_role_list"]/li')
    end
  end

  test 'creates agent' do
    skip('no run now')
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryBot.build(:agent)
    fill_in_form(unsaved_agent)
    click_link_or_button 'Create Agent'

    assert page.has_content?('Agent was successfully created')
  end

  test 'do not allow create agents duplicates' do
    skip('no run now')
    setup_environment
    agent = FactoryBot.create(:agent)
    visit new_admin_agent_path
    fill_in_form(agent)
    click_link_or_button 'Create Agent'
    assert page.has_content?('has already been taken')
  end

  test 'view agent' do
    skip('no run now')
    setup_environment
    visit admin_agents_path
    within('#agents_table') do
      within('tr', text: @admin_agent.email) do
        click_link_or_button 'Show'
      end
    end
    assert page.has_content?('Agent')
    assert page.has_content?(@admin_agent.email)
    assert page.has_content?(@admin_agent.username)
  end

  test 'update agent' do
    skip('no run now')
    setup_environment
    confirmed_agent = FactoryBot.create(:confirmed_agent)
    another_agent = FactoryBot.build(:confirmed_agent)
    visit admin_agents_path

    within('#agents_table') do
      within('tr', text: confirmed_agent.email) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_form(another_agent)
    click_link_or_button 'Update Agent'
    assert page.has_content?('Agent was successfully updated')
  end

  test 'destroy agent' do
    skip('no run now')
    setup_environment
    confirmed_agent = FactoryBot.create(:confirmed_agent)
    visit admin_agents_path

    within('#agents_table') do
      within('tr', text: confirmed_agent.email) do
        click_link_or_button 'Destroy'
        confirm_ok_js
      end
    end

    assert page.has_content?('Agent was successfully deleted')
    assert Agent.with_deleted.where(id: confirmed_agent.id).first
  end

  test 'search agent' do
    skip('no run now')
    setup_environment

    confirmed_agent = FactoryBot.create(:confirmed_agent)
    10.times { FactoryBot.create(:confirmed_agent) }

    visit admin_agents_path
    do_data_table_search('#agents_table_filter', confirmed_agent.email)
    within('#agents_table') do
      wait_until { assert page.has_content?(confirmed_agent.email) }
      within('tr', text: confirmed_agent.email) do
        click_link_or_button 'Edit'
      end
    end

    assert find_field('agent[email]').value == confirmed_agent.email
  end

  test 'create an agent with different password confirmation' do
    skip('no run now')
    setup_environment
    visit new_admin_agent_path
    fill_in 'agent[email]', with: 'testing@email.com'
    fill_in 'agent[username]', with: 'username'
    fill_in 'agent[password]', with: 'password'
    fill_in 'agent[password_confirmation]', with: 'pass'

    click_link_or_button 'Create Agent'
    assert page.has_content?("doesn't match Password")
  end

  test 'should display agents in order' do
    skip('no run now')
    setup_environment
    10.times { FactoryBot.create(:confirmed_agent) }
    visit admin_agents_path
    within('#agents_table') do
      assert page.has_content?(Agent.first.username)
      assert page.has_content?(Agent.last.username)
      find('#th_created_at').click
      find('#th_created_at').click
    end
  end

  test 'create agents with global roles' do
    setup_environment
    visit admin_agents_path
    %w[agent_roles_admin agent_roles_supervisor agent_roles_representative agent_roles_api agent_roles_landing agent_roles_fulfillment_managment agent_roles_agency].each do |global_role|
      click_on 'New Agent'
      unsaved_agent = FactoryBot.build(:agent)
      fill_in_form(unsaved_agent)
      choose(global_role)
      click_link_or_button 'Create Agent'
      assert page.has_content?('Agent was successfully created')
      click_on 'Back'
    end
  end

  test 'Reset Password at CS' do
    skip('no run now')
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)

    visit '/'
    click_link_or_button('Forgot your password?')
    fill_in 'agent[email]', with: @admin_agent.email
    click_link_or_button('Send me reset password instructions')

    page.has_content?('You will receive an email with instructions about how to reset your password in a few minutes.')

    @admin_agent.reload
    visit edit_agent_password_path(reset_password_token: @admin_agent.reset_password_token)

    fill_in 'agent[password]', with: 'newpassword'
    fill_in 'agent[password_confirmation]', with: 'newpassword'

    click_link_or_button 'Change my password'

    page.has_content?('Your password was changed successfully. You are now signed in.')
  end

  test 'create agent with global role and them remove that role.' do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryBot.build(:agent)

    fill_in_form(unsaved_agent)
    choose('agent_roles_admin')

    click_link_or_button 'Create Agent'

    assert page.has_content?('Agent was successfully created')
    click_link_or_button 'Edit'
    click_on 'clear'

    click_link_or_button 'Update Agent'
    assert page.has_content?('Agent was successfully updated')

    within('#global_roles') do
      assert page.has_no_content?('admin')
    end
    saved_agent = Agent.find_by_username(unsaved_agent.username)

    assert saved_agent.roles.blank?
  end

  #####################################################
  # CLUBS ROLES
  #####################################################

  def prepare_agents_with_club_roles
    club = FactoryBot.create(:simple_club_with_gateway)
    club2 = FactoryBot.create(:simple_club_with_gateway)
    club3 = FactoryBot.create(:simple_club_with_gateway)
    @agent_club_role_admin = FactoryBot.create(:agent)
    [club, club3].each do |club|
      club_role = ClubRole.new club_id: club.id
      club_role.role = 'admin'
      club_role.agent_id = @agent_club_role_admin.id
      club_role.save
    end
    @agent_club_role_representative = FactoryBot.create(:agent)
    club_role = ClubRole.new club_id: club.id
    club_role.role = 'representative'
    club_role.agent_id = @agent_club_role_representative.id
    club_role.save
    @agent_club_role_admin2 = FactoryBot.create(:agent)
    club_role = ClubRole.new club_id: club2.id
    club_role.role = 'admin'
    club_role.agent_id = @agent_club_role_admin2.id
    club_role.save
  end

  test 'Agent with club_role admin can not create agents with global roles' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    visit new_admin_agent_path
    assert page.has_no_content?('Global Roles')
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_admin']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_api']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_representative']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_supervisor']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_agency']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_fulfillment_managment']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_landing']")
  end

  test 'See agents with rol only for the club that you are seeing' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    visit admin_agents_path
    within('#agents_table') do
      find('tr', text: @agent_club_role_admin.email)
      assert page.has_no_content?(@agent_club_role_admin2.email)
    end
  end

  test 'Club role admin should be able to edit club roles' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    visit admin_agents_path
    within('#agents_table') do
      within('tr', text: @agent_club_role_representative.email) do
        click_link_or_button 'Edit'
      end
    end

    within('#club_role_table') do
      click_link_or_button 'Edit'
      select 'supervisor', from: "select_club_role_#{@agent_club_role_representative.club_roles.first.id}"
      confirm_javascript_ok
      click_link_or_button 'Update'
      assert page.has_content? "Club Role for #{@agent_club_role_representative.clubs.first.name} updated successfully."
    end
  end

  test 'Club role admin should be able to create agents with club roles' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)

    visit admin_agents_path
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      click_on 'New Agent'
      unsaved_agent = FactoryBot.build(:agent)
      fill_in_form(unsaved_agent)
      within('#club_role_table') do
        click_link_or_button 'Add'
        select role, from: '[club_roles_attributes][1][role]'
      end
      click_link_or_button 'Create Agent'
      assert page.has_content?('Agent was successfully created')
      click_on 'Back'
    end
  end

  test 'Club role admin can delete club roles, unless it is the last one.' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    aditional_club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new club_id: aditional_club.id
    club_role.role = 'admin'
    club_role.agent_id = @agent_club_role_admin.id
    club_role.save

    visit admin_agents_path
    within('#agents_table') do
      within('tr', text: @agent_club_role_representative.email) do
        click_link_or_button 'Edit'
      end
    end

    within('#club_role_table') do
      click_link_or_button 'Add'
      select 'supervisor', from: '[club_roles_attributes][1][role]'
      select aditional_club.name, from: '[club_roles_attributes][1][club_id]'
    end

    click_link_or_button 'Update Agent'
    assert page.has_content?('Agent was successfully updated.')

    click_link_or_button 'Edit'

    club_role_to_delete_first = @agent_club_role_representative.club_roles.first
    club_name_deleted = club_role_to_delete_first.club.name
    confirm_javascript_ok

    within('#club_role_table') do
      within("#tr_club_role_#{@agent_club_role_representative.club_roles.first.id}") do
        click_link_or_button 'Delete'
        confirm_ok_js
      end
      assert page.has_content?('Club Role deleted successfully')
      assert page.has_no_content?(club_name_deleted)
      within("#tr_club_role_#{@agent_club_role_representative.club_roles.last.id}") do
        click_link_or_button 'Delete'
        confirm_ok_js
      end
      assert page.has_content?(@agent_club_role_representative.club_roles.last.club.name)

      click_link_or_button 'Add'
      select 'supervisor', from: '[club_roles_attributes][1][role]'
    end

    click_link_or_button 'Update Agent'
    assert page.has_content?('Agent was successfully updated')

    @agent_club_role_representative.reload
    assert_equal @agent_club_role_representative.club_roles.count, 2
  end

  test 'Admin by club role should recover agents. global role to club role' do
    skip('no run now')
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    create_agent_destroy_it_and_recover_it(false, true)
  end

  test 'Admin by club role should recover agents. club role to club role' do
    skip('no run now')
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    create_agent_destroy_it_and_recover_it(false, false)
  end

  test 'Admin by role should not create agent that exist now' do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    create_agent_try_to_recover_it(false)
  end

  test 'Global Admin should recover agents. global role to global role' do
    skip('no run now')
    setup_environment
    create_agent_destroy_it_and_recover_it(true, true)
  end

  test 'Global Admin should recover agents. global role to club role' do
    skip('no run now')
    setup_environment
    create_agent_destroy_it_and_recover_it(false, true)
  end

  test 'Global Admin should recover agents. club role to global role' do
    skip('no run now')
    setup_environment
    create_agent_destroy_it_and_recover_it(true, false)
  end

  test 'Global Admin should recover agents. club role to club role' do
    skip('no run now')
    setup_environment
    create_agent_destroy_it_and_recover_it(false, false)
  end

  test 'Global Admin should not create agent that exist now' do
    setup_environment
    create_agent_try_to_recover_it(true)
  end
end
