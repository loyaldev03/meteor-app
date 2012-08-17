require 'test_helper' 
 
class DomainTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  test "create empty domain" do
    visit admin_partners_path
    assert page.has_content?('Partners')
    click_link_or_button 'Dashboard'
    assert page.has_content?('Partner')
    click_link_or_button 'Domains'
    assert page.has_content?("Domains")
    click_link_or_button 'New Domain'
    click_link_or_button 'Create Domain'
    assert page.has_content?(I18n.t('errors.messages.blank'))
  end

  test "create domain" do
    unsaved_domain = FactoryGirl.build(:simple_domain)
    visit domains_path(@partner.prefix)
    click_link_or_button 'New Domain'
    fill_in 'domain[url]', :with => unsaved_domain.url
    assert_difference('Domain.count') do
      click_link_or_button 'Create Domain'
    end
    assert page.has_content?(unsaved_domain.url)
  end

end