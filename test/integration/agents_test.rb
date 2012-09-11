require 'test_helper' 
 
class AgentsTest < ActionController::IntegrationTest
 

  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  # test "create empty agent" do
  #   visit admin_agents_path
  #   assert page.has_content?('Agents')
  #   click_link_or_button 'New Agent'
  #   assert page.has_content?('New Agent')     
  #   wait_until {
  #     assert current_path == new_admin_agent_path
  #   }
  #   click_link_or_button 'Create Agent'
  #   assert page.has_content?(I18n.t('errors.messages.blank'))
  # end

  # test "create agent" do
    
  #   visit new_admin_agent_path
  #   unsaved_agent = FactoryGirl.build(:agent)
  #   fill_in 'agent[email]', :with => unsaved_agent.email
  #   fill_in 'agent[username]', :with => unsaved_agent.username
  #   fill_in 'agent[password]', :with => unsaved_agent.password
  #   fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
  #   check('agent_roles_admin')

  #   assert_difference('Agent.count') do
  #     click_link_or_button 'Create Agent'
  #   end
  #   assert page.has_content?("Agent was successfully created")
  # end

  # test "create duplicated agent" do
  #   visit new_admin_agent_path
  #   fill_in 'agent[email]', :with => @admin_agent.email
  #   fill_in 'agent[username]', :with => @admin_agent.username
  #   fill_in 'agent[password]', :with => @admin_agent.password
  #   fill_in 'agent[password_confirmation]', :with => @admin_agent.password_confirmation
  #   assert_difference('Agent.count', 0) do
  #     click_link_or_button 'Create Agent'
  #   end
  #   assert page.has_content?(I18n.t('activerecord.errors.messages.taken'))
  # end

  # test "view agent" do
  #   visit admin_agents_path
  #   within("#agents_table") do
  #     wait_until {
  #       click_link_or_button "Show" #change for view button
  #     }
  #   end

  #   assert page.has_content?("Agent")
  #   assert page.has_content?(@admin_agent.email) 
  #   assert page.has_content?(@admin_agent.username) 
   
  # end

  # test "update agent" do
  #   confirmed_agent = FactoryGirl.create(:confirmed_agent)
  #   visit admin_agents_path
  #   within("#agents_table .even") do
  #     wait_until {
  #       click_link_or_button 'Edit'
  #     }    
  #   end
  #   fill_in 'agent[email]', :with => confirmed_agent.email
  #   fill_in 'agent[username]', :with => confirmed_agent.username
  #   fill_in 'agent[password]', :with => confirmed_agent.password
  #   fill_in 'agent[password_confirmation]', :with => confirmed_agent.password_confirmation
  #   assert_difference('Agent.count', 0) do
  #     click_link_or_button 'Update Agent'
  #   end
  #   assert page.has_content?("Agent was successfully updated")
  # end

  # test "destroy agent" do
  #   confirmed_agent = FactoryGirl.create(:confirmed_agent)
  #   visit admin_agents_path
  #   confirm_ok_js
  #   within("#agents_table .even") do
  #     wait_until {
  #       click_link_or_button 'Destroy'
  #     }    
  #   end
  #   assert page.has_content?("Agent was successfully deleted")
  #   assert Agent.with_deleted.where(:id => confirmed_agent.id).first
  # end

  # test "search agent" do
  #   visit admin_agents_path

  #   10.times{ FactoryGirl.create(:confirmed_agent) }

  #   confirmed_agent = FactoryGirl.create(:confirmed_agent)
  #   do_data_table_search("#agents_table_filter", confirmed_agent.email)

  #   within("#agents_table") do
  #     wait_until {
  #       assert page.has_content?(confirmed_agent.email)
  #       click_link_or_button 'Edit'
  #     }    
  #   end

  #   assert find_field('agent[email]').value == confirmed_agent.email
  # end

  # test "create admin agent" do
  #   visit new_admin_agent_path
  #   unsaved_agent = FactoryGirl.build(:agent)
  #   fill_in 'agent[email]', :with => unsaved_agent.email
  #   fill_in 'agent[username]', :with => unsaved_agent.username
  #   fill_in 'agent[password]', :with => unsaved_agent.password
  #   fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
  #   check('agent_roles_admin')

  #   assert_difference('Agent.count') do
  #     click_link_or_button 'Create Agent'
  #   end
    
  #   assert page.has_content?("Agent was successfully created")
  # end

  # test "do not allow to create new agent with special characters" do
  #   visit new_admin_agent_path
  #   fill_in 'agent[email]', :with => "&%$"
  #   click_link_or_button 'Create Agent'
  #   assert page.has_content?("is invalid")
  # end
  
  # test "create an agent with different password confirmation" do
  #   visit new_admin_agent_path
  #   fill_in 'agent[email]', :with => 'testing@email.com'
  #   fill_in 'agent[password]', :with => "password"
  #   fill_in 'agent[password_confirmation]', :with => 'pass'

  #   click_link_or_button 'Create Agent'

  #   assert page.has_content?("doesn't match confirmation")
  # end 

  # test "should display agents in order" do
  #   10.times{ FactoryGirl.create(:confirmed_agent) }
  #   visit admin_agents_path
  
  #   within("#agents_table")do
  #     wait_until{
  #       assert page.has_content?(Agent.first.username)
  #     }
  #     wait_until{
  #       find("#th_created_at").click
  #       find("#th_created_at").click
  #     }
  #     wait_until{
  #       assert page.has_content?(Agent.last.username)
  #     }
  #   end
  # end

  test "create agent with supervisor role" do
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    check('agent_roles_supervisor')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    puts saved_agent.roles
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, ['supervisor']
  end

  test "create agent with representative role" do
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    check('agent_roles_representative')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    puts saved_agent.roles
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, ['representative']
  end

  test "create agent with api role" do
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    check('agent_roles_api')

    assert_difference('Agent.count') do
      click_link_or_button 'Create Agent'
    end
    
    assert page.has_content?("Agent was successfully created")
    
    saved_agent = Agent.last
    puts saved_agent.roles
    assert_equal saved_agent.email, unsaved_agent.email
    assert_equal saved_agent.roles, ['api']
  end
end