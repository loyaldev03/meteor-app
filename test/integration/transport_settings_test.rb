require 'test_helper'

class TransportSettingsTest < ActionDispatch::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)            
  end

  def login_general_admin(type)
    @admin_agent = FactoryGirl.create(type)
    sign_in_as(@admin_agent)
  end

  test "should create Facebook Transport Settings " do
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    click_link_or_button 'new_transport_setting'
    select 'facebook', :from => 'transport_setting[transport]'
    fill_in 'transport_setting[client_id]', :with => 4512654444444
    fill_in 'transport_setting[client_secret]', :with => '5709da9e040bae4e24'
    fill_in 'transport_setting[access_token]', :with => 'EAAWlTN0I0ZCoBAKu3XGZCcgixXbIQZDZD'
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for facebook was successfully created.")
  end

  test "should edit Facebook Transport Settings" do
    transport_settings_facebook = FactoryGirl.create(:transport_settings_facebook, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'transport_setting[client_id]', :with => 4512654444444
    fill_in 'transport_setting[client_secret]', :with => '5709da9e040bae4e24'
    fill_in 'transport_setting[access_token]', :with => 'EAAWlTN0I0ZCoBAKu3XGZCcgixXbIQZDZD'
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for facebook was successfully updated.")
  end

  test "should create Mailchimp Transport Settings " do
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    click_link_or_button 'new_transport_setting'
    select 'mailchimp', :from => 'transport_setting[transport]'
    fill_in 'transport_setting[api_key]', :with => 'skdfasdfasd6546554asd6f4a6sdfa645'    
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for mailchimp was successfully created.")
  end

  test "should edit Mailchimp Transport Settings" do
    transport_settings_mailchimp = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'transport_setting[api_key]', :with => 'skdfasdfasd6546554asd6f4a6sdfa645'     
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for mailchimp was successfully updated.")
  end

  test "should see Mailchimp Transport Settings" do
    transport_settings_mailchimp = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Mailchimp")
    click_link_or_button 'Back'
  end

  test "should see Facebook Transport Settings" do
    transport_settings_facebook = FactoryGirl.create(:transport_settings_facebook, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Facebook")
    click_link_or_button 'Back'
  end
end



