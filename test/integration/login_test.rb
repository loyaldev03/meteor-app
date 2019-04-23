require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  test 'admin_agent_login' do
    skip('no run now')
    admin_user = FactoryBot.create(:confirmed_admin_agent)
    sign_in_as(admin_user)
    assert page.has_content?('Signed in successfully')
  end

  test 'admin_agent_logout' do
    skip('no run now')
    admin_agent = FactoryBot.create(:confirmed_admin_agent)
    sign_in_as(admin_agent)
    page.execute_script("window.jQuery('.dropdown').addClass('open')")

    within('.navbar') do
      page.find('#link_logout').click
    end
    visit root_path
    assert page.has_content?('You need to sign in or sign up before continuing')
  end

  test 'no_login' do
    skip('no run now')
    visit root_path
    user = FactoryBot.build(:agent)
    sign_in_as(user)
    assert page.has_content?('Invalid email or password')
  end
end
