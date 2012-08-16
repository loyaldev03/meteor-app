require 'test_helper' 
 
class AgentsTest < ActionController::IntegrationTest
 

  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
  end

  test "create_empty_agent" do
    sign_in_as(@admin_agent)
    visit admin_agents_path
    assert page.has_content?('Agents')
    click_link_or_button 'New Agent'
    assert page.has_content?('New Agent')
    click_link_or_button 'Create Agent'
    assert page.has_content?("can't be blank")
    sign_out
  end

  test "create_agent" do
    sign_in_as(@admin_agent)
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    click_link_or_button 'Create Agent'
    assert page.has_content?("Agent was successfully created")
    sign_out
  end

  test "create_duplicated_agent" do
    sign_in_as(@admin_agent)
    visit new_admin_agent_path
    fill_in 'agent[email]', :with => @admin_agent.email
    fill_in 'agent[username]', :with => @admin_agent.username
    fill_in 'agent[password]', :with => @admin_agent.password
    fill_in 'agent[password_confirmation]', :with => @admin_agent.password_confirmation
    click_link_or_button 'Create Agent'
    assert page.has_content?("has already been taken")
    sign_out
  end

  test "view_agent" do
    sign_in_as(@admin_agent)
    visit admin_agents_path
    wait_until {
      click_link_or_button 'Edit'
    }
    assert page.has_content?("Edit Agent")
    assert find_field('agent_email').value == @admin_agent.email
    assert find_field('agent_username').value == @admin_agent.username 
    sign_out
  end

  test "update_agent" do
    sign_in_as(@admin_agent)
    confirmed_agent = FactoryGirl.create(:confirmed_agent)
    visit admin_agents_path
    within(".even") do
      wait_until {
        click_link_or_button 'Edit'
      }    
    end
    fill_in 'agent[email]', :with => confirmed_agent.email
    fill_in 'agent[username]', :with => confirmed_agent.username
    fill_in 'agent[password]', :with => confirmed_agent.password
    fill_in 'agent[password_confirmation]', :with => confirmed_agent.password_confirmation
    click_link_or_button 'Update Agent'
    assert page.has_content?("Agent was successfully updated")
    sign_out
  end

  test "destroy_agent" do
    sign_in_as(@admin_agent)
    confirmed_agent = FactoryGirl.create(:confirmed_agent)
    visit admin_agents_path
    confirm_ok_js
    within(".even") do
      wait_until {
        click_link_or_button 'Destroy'
      }    
    end

    assert page.has_content?("Agent was successfully deleted")
    sign_out
  end

  test "create_admin_agent" do
    sign_in_as(@admin_agent)
    visit new_admin_agent_path
    unsaved_agent = FactoryGirl.build(:agent)
    fill_in 'agent[email]', :with => unsaved_agent.email
    fill_in 'agent[username]', :with => unsaved_agent.username
    fill_in 'agent[password]', :with => unsaved_agent.password
    fill_in 'agent[password_confirmation]', :with => unsaved_agent.password_confirmation
    check('agent_roles_admin')
    click_link_or_button 'Create Agent'
    assert page.has_content?("Agent was successfully created")
    sign_out
  end
  


end