require 'test_helper'

class TransportSettingsTest < ActionDispatch::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tsfacebook = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)
    @tsmailchimp = FactoryGirl.build(:transport_settings_mailchimp, :club_id => @club.id)
  end

  def login_general_admin(type)
    @admin_agent = FactoryGirl.create(type)
    sign_in_as(@admin_agent)
  end

  def fill_in_form(transport = nil, options ={})
    select transport, from: 'transport_setting[transport]' if not transport.nil?        
    options.each do |credential, value|
      fill_in "transport_setting[#{credential}]", with: value
    end
  end

  test "should create Facebook Transport Settings " do
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    click_link_or_button 'new_transport_setting' 
    fill_in_form('facebook', options ={client_id: @tsfacebook.client_id, client_secret: @tsfacebook.client_secret, access_token: @tsfacebook.access_token})       
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for facebook was successfully created.")
    assert page.has_content?(@tsfacebook.client_id)
    assert page.has_content?(@tsfacebook.client_secret)
    assert page.has_content?(@tsfacebook.access_token)
  end

  test "should edit Facebook Transport Settings" do
    transport_settings_facebook = FactoryGirl.create(:transport_settings_facebook, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {client_id: @tsfacebook.client_id, client_secret: @tsfacebook.client_secret, access_token: @tsfacebook.access_token})           
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for facebook was successfully updated.")
    assert page.has_content?(@tsfacebook.client_id)
    assert page.has_content?(@tsfacebook.client_secret)
    assert page.has_content?(@tsfacebook.access_token)
  end

  test "should create Mailchimp Transport Settings " do
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    click_link_or_button 'new_transport_setting'
    fill_in_form('mailchimp', {api_key: @tsmailchimp.api_key})              
    click_link_or_button 'Create Transport setting'    
    assert page.has_content?("The transport setting for mailchimp was successfully created.")
    assert page.has_content?(@tsmailchimp.api_key)
  end

  test "should edit Mailchimp Transport Settings" do
    transport_settings_mailchimp = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id)
    login_general_admin(:confirmed_admin_agent)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {api_key: @tsmailchimp.api_key})   
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for mailchimp was successfully updated.")
    assert page.has_content?(@tsmailchimp.api_key)
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



