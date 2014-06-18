require 'test_helper' 
 
class AgentsTest < ActionController::IntegrationTest
 

  def setup_environment
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  test "create empty agent" do
    setup_environment
    visit admin_agents_path
    assert page.has_content?('Agents')
    click_link_or_button 'New Agent'
    assert page.has_content?('New Agent')     
    assert current_path == new_admin_agent_path
    click_link_or_button 'Create Agent'
    assert page.has_content?(I18n.t('errors.messages.blank'))
  end

  test "create agent" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_admin')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    assert page.has_content?("Agent was successfully created")
  end

  test "create duplicated agent" do
    setup_environment
    visit new_admin_agent_path
    fill_in 'agent[email]', :with => @admin_agent.email
    fill_in 'agent[username]', :with => @admin_agent.username
    fill_in 'agent[password]', :with => @admin_agent.password
    fill_in 'agent[password_confirmation]', :with => @admin_agent.password_confirmation
    assert_difference('Agent.count', 0) do
      click_link_or_button 'Create Agent'
    end
    assert page.has_content?(I18n.t('activerecord.errors.messages.taken'))
  end

  test "view agent" do
    setup_environment
    visit admin_agents_path
    within("#agents_table") do 
      within("tr", :text => @admin_agent.email) do 
        click_link_or_button 'Show'
      end
    end    

    assert page.has_content?("Agent")
    assert page.has_content?(@admin_agent.email) 
    assert page.has_content?(@admin_agent.username) 
  end

  test "update agent" do
    setup_environment
    confirmed_agent = FactoryGirl.create(:confirmed_agent)
    visit admin_agents_path

    within("#agents_table") do 
      within("tr", :text => confirmed_agent.email) do 
        click_link_or_button 'Edit'
      end
    end    

    fill_in 'agent[email]', :with => confirmed_agent.email
    fill_in 'agent[username]', :with => confirmed_agent.username
    fill_in 'agent[password]', :with => confirmed_agent.password
    fill_in 'agent[password_confirmation]', :with => confirmed_agent.password_confirmation
    assert_difference('Agent.count', 0) do
      click_link_or_button 'Update Agent'
    end
  
    assert page.has_content?("Agent was successfully updated")
  end

  test "destroy agent" do
    setup_environment
    confirmed_agent = FactoryGirl.create(:confirmed_agent)
    visit admin_agents_path
    confirm_ok_js

    within("#agents_table") do 
      within("tr", :text => confirmed_agent.email) do 
        click_link_or_button 'Destroy'
      end
    end

    assert page.has_content?("Agent was successfully deleted")
    assert Agent.with_deleted.where(:id => confirmed_agent.id).first
  end

  test "search agent" do
    setup_environment

    confirmed_agent = FactoryGirl.create(:confirmed_agent)
    10.times{ FactoryGirl.create(:confirmed_agent) }

    visit admin_agents_path
    do_data_table_search("#agents_table_filter", confirmed_agent.email)
    within("#agents_table") do 
      sleep 5      
      assert page.has_content?(confirmed_agent.email)
      within("tr", :text => confirmed_agent.email) do 
        click_link_or_button 'Edit'
      end
    end    

    assert find_field('agent[email]').value == confirmed_agent.email
  end

  test "create admin agent" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_admin')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
  end

  test "do not allow to create new agent with special characters" do
    setup_environment
    visit new_admin_agent_path
    fill_in 'agent[email]', :with => "&%$"
    click_link_or_button 'Create Agent'
    assert page.has_content?("is invalid")
  end
  
  test "create an agent with different password confirmation" do
    setup_environment
    visit new_admin_agent_path
    fill_in 'agent[email]', :with => 'testing@email.com'
    fill_in 'agent[password]', :with => "password"
    fill_in 'agent[password_confirmation]', :with => 'pass'

    click_link_or_button 'Create Agent'

    assert page.has_content?("doesn't match confirmation")
  end 

  test "should display agents in order" do
    setup_environment
    10.times{ FactoryGirl.create(:confirmed_agent) }
    visit admin_agents_path
  
    within("#agents_table")do
      assert page.has_content?(Agent.first.username)
      assert page.has_content?(Agent.last.username)
      find("#th_created_at").click
      find("#th_created_at").click
    end
  end
  
  test "create agent with supervisor role" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_supervisor')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, 'supervisor'
  end

  test "create agent with representative role" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_representative')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, 'representative'
  end

  test "create agent with api role" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_api')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, 'api'
  end

  test "create agent like Administrator, Supervisor and representative" do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    
    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")    
  end

  test "Reset Password at CS" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
   
    visit '/'
    click_link_or_button("Forgot your password?")
    fill_in "agent[login]", :with => @admin_agent.email
    click_link_or_button("Send me reset password instructions")

    page.has_content?("You will receive an email with instructions about how to reset your password in a few minutes.")

    @admin_agent.reload
    visit edit_agent_password_path(:reset_password_token => @admin_agent.reset_password_token )

    fill_in "agent[password]", :with => "newpassword"
    fill_in "agent[password_confirmation]", :with => "newpassword"

    click_link_or_button "Change my password"

    page.has_content?("Your password was changed successfully. You are now signed in.")
  end

  test "create agent with global role and them remove that role." do
    setup_environment
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)

    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    choose('agent_roles_admin')

    click_link_or_button 'Create Agent'

    assert page.has_content?("Agent was successfully created")
    click_link_or_button 'Edit'
    click_on "clear"

    click_link_or_button 'Update Agent'
    assert page.has_content?("Agent was successfully updated")

    within("#global_roles") do
      assert page.has_no_content?("admin")
    end
    saved_agent = Agent.find_by_username(unsaved_agent.username)

    assert saved_agent.roles.blank?
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  def prepare_agents_with_club_roles
    @agent_club_role_admin = FactoryGirl.create(:agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.role = "admin"
    club_role.agent_id = @agent_club_role_admin.id
    club_role.save
    @agent_club_role_admin2 = FactoryGirl.create(:agent)
    club2 = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club2.id
    club_role.role = "admin"
    club_role.agent_id = @agent_club_role_admin2.id
    club_role.save
  end

  test "Agent with club_role admin can not create agents with global roles" do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    visit new_admin_agent_path
    assert page.has_no_content?("Global Roles")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_admin']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_api']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_representative']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_supervisor']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_agency']")
    assert page.has_no_selector?(:xpath, "//input[@id='agent_roles_fulfillment_managment']")
  end

  test "See agents with rol only for the club that you are seeing" do
    prepare_agents_with_club_roles
    sign_in_as(@agent_club_role_admin)
    visit admin_agents_path
    within("#agents_table") do 
      find("tr", :text => @agent_club_role_admin.email)
      assert page.has_no_content?(@agent_club_role_admin2.email)
    end
  end
end
