require 'test_helper' 
 
class DomainTest < ActionDispatch::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  test "create empty domain" do
    visit admin_partners_path
    assert page.has_content?('Partners')
    within("#partners_table")do 
      within('tr', text: @partner.name, exact: true){click_link_or_button 'Dashboard'}
    end
    assert page.has_content?('Partner')
    within(".sidebar-nav"){ click_link_or_button 'Domains' }

    assert page.has_content?("Domains")

    click_link_or_button 'New Domain'
    assert_difference('Domain.count', 0) do
      click_link_or_button 'Create Domain'
    end
    assert_equal new_domain_path(partner_prefix: @partner.prefix), current_path 
  end

  test "create domain" do
    unsaved_domain = FactoryGirl.build(:simple_domain)
    visit domains_path(@partner.prefix)
    click_link_or_button 'New Domain'
    
    fill_in 'domain[url]', with: unsaved_domain.url
    assert_difference('Domain.count') do
      click_link_or_button 'Create Domain'
    end
    assert page.has_content?(unsaved_domain.url)
  end

  test "create duplicate domain" do
    saved_domain = FactoryGirl.create(:simple_domain)
    visit domains_path(@partner.prefix)
    click_link_or_button 'New Domain'
    fill_in 'domain[url]', with: saved_domain.url
    click_link_or_button 'Create Domain'
    assert page.has_content?('has already been taken')
  end

  test "can read domain" do
    saved_domain = FactoryGirl.create(:simple_domain, partner_id: @partner.id)
    visit admin_partners_path
    within("#partners_table") do
      within('tr', text: @partner.name, exact: true){click_link_or_button 'Dashboard'}
    end
    click_link_or_button 'Domains'
    assert page.has_content?(saved_domain.url)
  end

  test "can update domain" do
    saved_domain = FactoryGirl.create(:simple_domain, partner_id: @partner.id)
    visit domains_path(@partner.prefix)
    within("#domains_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'domain[url]', with: 'http://test.com.ar'
    fill_in 'domain[description]', with: 'new description'
    fill_in 'domain[data_rights]', with: 'new data rights'
    check('domain[hosted]')
    click_link_or_button 'Update Domain'
    saved_domain.reload
    assert page.has_content?("The domain #{saved_domain.url} was successfully updated.")
    assert_equal saved_domain.url, 'http://test.com.ar'
    assert_equal saved_domain.description, 'new description'
    assert_equal saved_domain.data_rights, 'new data rights'
  end

  test "should delete domain" do
    saved_domain = FactoryGirl.create(:simple_domain, partner_id: @partner.id)
    second_saved_domain = FactoryGirl.create(:simple_domain, partner_id: @partner.id)
    visit domains_path(@partner.prefix)

    within("#domains_table") do
      first(:link, 'Destroy').click
      confirm_ok_js
    end
    assert page.has_content?("Domain #{saved_domain.url} was successfully destroyed")
    assert Domain.with_deleted.where(id: saved_domain.id).first
  end
end