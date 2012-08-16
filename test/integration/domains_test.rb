require 'test_helper' 
 
class DomainTest < ActionController::IntegrationTest
 
  # setup do
  #   @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
  #   sign_in_as(@admin_agent)
  #   @partner = FactoryGirl.create(:partner)
  #   @unsaved_domain = FactoryGirl.build(:domain)
  # end

  # test "create_empty_domain" do
  #   visit admin_partners_path
  #   assert page.has_content?('Partners')
  #   click_link_or_button 'Dashboard'
  #   assert page.has_content?('Partner')
  #   click_link_or_button 'Domains'
  #   assert page.has_content?("Domains")
  #   click_link_or_button 'New Domain'
  #   click_link_or_button 'Create Domain'
  # end

  # test "create_domain" do
  #   visit domains_path(@partner)
  #   click_link_or_button 'New Domain'
  #   fill_in 'domain_url', :with => @unsaved_domain.url
  #   click_link_or_button 'Create Domain'
  # end

end