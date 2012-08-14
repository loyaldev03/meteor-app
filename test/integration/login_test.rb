require 'integration_test_helper' 
 
class LoginTest < ActionController::IntegrationTest
 
  setup do
    
  end

  test "admin_agent_login" do
  	admin_user = FactoryGirl.create(:confirmed_admin_agent)
    visit root_path
    assert page.has_content?('Sign in')
    fill_in 'agent_login', :with => admin_user.username
    fill_in 'agent_password', :with => admin_user.password
    click_button 'Sign in'
    assert page.has_content?('Signed in successfully')
  end

  test "no_login" do
    visit root_path
    assert page.has_content?('Sign in')
    fill_in 'agent_login', :with => 'no_user_123456789'
    fill_in 'agent_password', :with => 'no_password_123456789'
    click_button 'Sign in'
    assert page.has_content?('Invalid email or password')
  end

 
end