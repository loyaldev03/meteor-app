require 'test_helper' 
 
class LoginTest < ActionDispatch::IntegrationTest
 
  setup do
  end

  test "admin_agent_login" do
  	admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(admin_user)
    assert page.has_content?('Signed in successfully')
  end

  test "admin_agent_logout" do
  	admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(admin_agent)
    page.execute_script("window.jQuery('.dropdown').addClass('open')")
#     
    within(".navbar")do
      #click_link_or_button I18n.t('menu.logout')
      page.find('#link_logout').click
    end
    visit root_path
    assert page.has_content?("You need to sign in or sign up before continuing")
  end

  test "no_login" do
    visit root_path
    user = FactoryGirl.build(:agent)
    sign_in_as(user)
    assert page.has_content?('Invalid email or password')
  end

end
