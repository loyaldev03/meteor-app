require 'test_helper' 
 
class PartnersTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
    @partner = FactoryGirl.build(:partner)
    @domain = FactoryGirl.build(:domain)
  end

  test "create_empty_partner" do
    visit admin_partners_path
    assert page.has_content?('Partners')
    click_link_or_button 'New Partner'
    assert page.has_content?('New Partner')
    click_link_or_button 'Create Partner'
    assert page.has_content?(I18n.t('errors.messages.blank')) #page.has_content?("errors")
    sign_out
  end

  test "create_partner" do
    visit new_admin_partner_path
    fill_in 'partner_name', :with => @partner.name
    fill_in 'partner_prefix', :with => @partner.prefix
    fill_in 'partner_description', :with => @partner.description
    fill_in 'domain_url', :with => @domain.url
    check('domain_hosted')
    click_link_or_button 'Create Partner'
    assert page.has_content?("The partner #{@partner.prefix} - #{@partner.name} was successfully created")
    sign_out
  end
  
  test "create_duplicated_partner" do
    internal_partner = FactoryGirl.create(:partner)
    internal_domain = FactoryGirl.create(:domain)
    visit new_admin_partner_path
    fill_in 'partner_name', :with => internal_partner.name
    fill_in 'partner_prefix', :with => internal_partner.prefix
    fill_in 'domain_url', :with => internal_domain.url
    click_link_or_button 'Create Partner'
    assert page.has_content?(I18n.t('activerecord.errors.messages.taken'))
  end

  # test "update_partner" do
  #   sign_in_as(@admin_agent)
  #   confirmed_agent = FactoryGirl.create(:confirmed_agent)
  #   visit visit admin_partners_path
  #   within(".even") do
  #     wait_until {
  #       click_link_or_button 'Edit'
  #     }    
  #   end
  #   fill_in 'agent[email]', :with => confirmed_agent.email
  #   fill_in 'agent[username]', :with => confirmed_agent.username
  #   fill_in 'agent[password]', :with => confirmed_agent.password
  #   fill_in 'agent[password_confirmation]', :with => confirmed_agent.password_confirmation
  #   click_link_or_button 'Update Agent'
  #   assert page.has_content?("Agent was successfully updated")
  #   sign_out
  # end

end