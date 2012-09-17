require 'test_helper' 
 
class DomainTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  # test "create empty domain" do
  #   visit admin_partners_path
  #   assert page.has_content?('Partners')
  #   click_link_or_button 'Dashboard'
  #   assert page.has_content?('Partner')
  #   click_link_or_button 'Domains'
  #   assert page.has_content?("Domains")
  #   click_link_or_button 'New Domain'
  #   click_link_or_button 'Create Domain'
  #   assert page.has_content?(I18n.t('errors.messages.blank'))
  # end

  # test "create domain" do
  #   unsaved_domain = FactoryGirl.build(:simple_domain)
  #   visit domains_path(@partner.prefix)
  #   click_link_or_button 'New Domain'
  #   fill_in 'domain[url]', :with => unsaved_domain.url
  #   assert_difference('Domain.count') do
  #     click_link_or_button 'Create Domain'
  #   end
  #   assert page.has_content?(unsaved_domain.url)
  # end

  # test "create duplicate domain" do
  #   saved_domain = FactoryGirl.create(:simple_domain)
  #   visit domains_path(@partner.prefix)
  #   click_link_or_button 'New Domain'
  #   fill_in 'domain[url]', :with => saved_domain.url
  #   click_link_or_button 'Create Domain'
  #   assert page.has_content?('has already been taken')
  # end

  # test "can read domain" do
  #   saved_domain = FactoryGirl.create(:simple_domain, :partner_id => @partner.id)
  #   visit admin_partners_path
  #   within("#partners_table") do
  #     wait_until{
  #       click_link_or_button 'Dashboard'
  #     }
  #   end
  #   click_link_or_button 'Domains'
  #   assert page.has_content?(saved_domain.url)
  # end

  # test "can update domain" do
  #   saved_domain = FactoryGirl.create(:simple_domain, :partner_id => @partner.id)
  #   visit domains_path(@partner.prefix)
  #   within("#domains_table") do
  #     wait_until{
  #       click_link_or_button 'Edit'
  #     }
  #   end
  #   fill_in 'domain[url]', :with => 'http://test.com.ar'
  #   fill_in 'domain[description]', :with => 'new description'
  #   fill_in 'domain[data_rights]', :with => 'new data rights'
  #   check('domain[hosted]')
  #   click_link_or_button 'Update Domain'
  #   saved_domain.reload
  #   assert page.has_content?("The domain #{saved_domain.url} was successfully updated.")
  #   assert_equal saved_domain.url, 'http://test.com.ar'
  #   assert_equal saved_domain.description, 'new description'
  #   assert_equal saved_domain.data_rights, 'new data rights'
  # end

  test "should delete domain" do
    saved_domain = FactoryGirl.create(:simple_domain, :partner_id => @partner.id)
    second_saved_domain = FactoryGirl.create(:simple_domain, :partner_id => @partner.id)
    visit domains_path(@partner.prefix)
    confirm_ok_js
    within("#domains_table") do
      wait_until{
        click_link_or_button 'Destroy'
      }
    end
    wait_until{
      assert page.has_content?("Domain #{saved_domain.url} was successfully destroyed")
      assert Domain.with_deleted.where(:id => saved_domain.id).first
    }
  end

  # test "should see all clubs as admin on my clubs section" do
  #   10.times{ FactoryGirl.create(:simple_domain) }

  # end
end