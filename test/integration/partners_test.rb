require 'test_helper' 
 
class PartnersTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  test "create_empty_partner" do
    visit admin_partners_path
    assert page.has_content?('Partners')
    click_link_or_button 'New Partner'
    assert page.has_content?('New Partner')
    click_link_or_button 'Create Partner'
    assert page.has_content?("errors")
    assert page.has_content?(I18n.t('errors.messages.blank'))
  end

  test "Required fields marks in New Partner page" do
    visit admin_partners_path
    assert page.has_content?('Partners')
    click_link_or_button 'New Partner'
    within("#div_prefix") do
      assert page.has_css?('.required_asterisk')
    end
    within("#div_name") do
      assert page.has_css?('.required_asterisk')
    end
    within("#div_domain_url") do
      assert page.has_css?('.required_asterisk')
    end
  end
  

  test "create partner" do
    unsaved_partner = FactoryGirl.build(:partner)
    unsaved_domain = FactoryGirl.build(:simple_domain)

    visit new_admin_partner_path
    fill_in 'partner[name]', with: unsaved_partner.name
    fill_in 'partner[prefix]', with: unsaved_partner.prefix
    fill_in 'partner[description]', with: unsaved_partner.description
    fill_in 'partner[contract_uri]', with: unsaved_partner.contract_uri
    fill_in 'partner[website_url]', with: unsaved_partner.website_url
    fill_in 'domain_url', with: unsaved_domain.url
    check('domain_hosted')
    assert_difference('Partner.count') do
      click_link_or_button 'Create Partner'
    end
    assert page.has_content?("The partner #{unsaved_partner.prefix} - #{unsaved_partner.name} was successfully created")
    
  end
  
  test "create duplicated partner" do
    saved_partner = FactoryGirl.create(:partner)
    saved_domain = FactoryGirl.create(:simple_domain)
    visit new_admin_partner_path
    fill_in 'partner[name]', with: saved_partner.name
    fill_in 'partner[prefix]', with: saved_partner.prefix
    fill_in 'domain_url', with: saved_domain.url
    assert_difference('Partner.count', 0) do
      click_link_or_button 'Create Partner'
    end
    assert page.has_content?("Domains url has already been taken")
  end

  test "create a partner with invalid characters" do
    visit new_admin_partner_path
    fill_in 'partner[name]', with: '!"#$%&/()'
    fill_in 'partner[prefix]', with: '!"#$%&/()'

    assert_difference('Partner.count', 0) do
      click_link_or_button 'Create Partner'
    end
    assert page.has_content?('Name is invalid')
    assert page.has_content?('Prefix is invalid')
  end

  test "Should display partner" do
    saved_partner = FactoryGirl.create(:partner)
    visit admin_partners_path
    within("#partners_table") do
        click_link_or_button 'Dashboard'
    end
    assert page.has_content?(saved_partner.prefix)
    assert page.has_content?(saved_partner.name)
    assert page.has_content?('Back')
    assert page.has_content?('Edit')  
  end

  test "Should update partner" do
    saved_partner = FactoryGirl.create(:partner)
    visit admin_partners_path
    within("#partners_table") do
        click_link_or_button 'Edit'
    end
    fill_in 'partner[name]', with: 'My new name'
    click_link_or_button 'Update Partner'
    saved_partner.reload
    assert page.has_content?("The partner #{saved_partner.prefix} - #{saved_partner.name} was successfully updated.")
  end

end