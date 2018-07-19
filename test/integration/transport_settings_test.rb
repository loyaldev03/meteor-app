require 'test_helper'

class TransportSettingsTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tsfacebook = FactoryBot.build(:transport_settings_facebook, :club_id => @club.id)
    @tsmailchimp = FactoryBot.build(:transport_settings_mailchimp, :club_id => @club.id)
    @tsgoogletagmanager = FactoryBot.build(:transport_settings_google_tag_manager, :club_id => @club.id)
    @tsgoogleanalytics = FactoryBot.build(:transport_settings_google_analytics, :club_id => @club.id)
    @tsstore = FactoryBot.build(:transport_settings_store, :club_id => @club.id)
    sign_in_as(@admin_agent)
  end

  def fill_in_form(transport = nil, options ={})
    select transport, from: 'transport_setting[transport]' if not transport.nil?        
    options.each do |credential, value|
      fill_in "transport_setting[#{credential}]", with: value
    end
  end

  test "should see Facebook Transport Settings" do
    transport_settings_facebook = FactoryBot.create(:transport_settings_facebook, :club_id => @club.id)    
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Facebook")
    click_link_or_button 'Back'
  end

  test "should create Facebook, Mailchimp, Google Tag Manager, Google Analytics and Store Transport Settings " do    
    visit transport_settings_path(@partner_prefix, @club.name)
    click_link_or_button 'new_transport_setting' 
    fill_in_form('Facebook', options ={client_id: @tsfacebook.client_id, client_secret: @tsfacebook.client_secret, access_token: @tsfacebook.access_token})       
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for Facebook was successfully created.")
    assert page.has_content?(@tsfacebook.client_id)
    assert page.has_content?(@tsfacebook.client_secret)
    assert page.has_content?(@tsfacebook.access_token)

    click_link_or_button 'Back'
    click_link_or_button 'new_transport_setting'
    fill_in_form('Mailchimp', {api_key: @tsmailchimp.api_key})              
    click_link_or_button 'Create Transport setting'    
    assert page.has_content?("The transport setting for Mailchimp was successfully created.")
    assert page.has_content?(@tsmailchimp.api_key)

    click_link_or_button 'Back'
    click_link_or_button 'new_transport_setting' 
    fill_in_form('Google Tag Manager', options ={container_id: @tsgoogletagmanager.container_id})       
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for Google Tag Manager was successfully created.")
    assert page.has_content?(@tsgoogletagmanager.container_id)

    click_link_or_button 'Back'
    click_link_or_button 'new_transport_setting' 
    fill_in_form('Google Analytics', options ={tracking_id: @tsgoogleanalytics.tracking_id})       
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for Google Analytics was successfully created.")
    assert page.has_content?(@tsgoogleanalytics.tracking_id)

    click_link_or_button 'Back'
    click_link_or_button 'new_transport_setting' 
    fill_in_form('Store', options ={url: @tsstore.url, api_token: @tsstore.api_token})       
    click_link_or_button 'Create Transport setting'
    assert page.has_content?("The transport setting for Store was successfully created.")
    assert page.has_content?(@tsstore.url)
    assert page.has_content?(@tsstore.api_token)
  end

  test "should edit Facebook Transport Settings" do
    transport_settings_facebook = FactoryBot.create(:transport_settings_facebook, :club_id => @club.id)    
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {client_id: @tsfacebook.client_id, client_secret: @tsfacebook.client_secret, access_token: @tsfacebook.access_token})           
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for Facebook was successfully updated.")
    assert page.has_content?(@tsfacebook.client_id)
    assert page.has_content?(@tsfacebook.client_secret)
    assert page.has_content?(@tsfacebook.access_token)      
  end

  test "should see Mailchimp Transport Settings" do
    transport_settings_mailchimp = FactoryBot.create(:transport_settings_mailchimp, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Mailchimp")
    click_link_or_button 'Back'
  end

  test "should edit Mailchimp Transport Settings" do
    transport_settings_mailchimp = FactoryBot.create(:transport_settings_mailchimp, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {api_key: @tsmailchimp.api_key})   
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for Mailchimp was successfully updated.")
    assert page.has_content?(@tsmailchimp.api_key)
  end

  test "should see Google tag manager Transport Settings" do
    transport_settings_google_tag_manager = FactoryBot.create(:transport_settings_google_tag_manager, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Google Tag Manager")
    click_link_or_button 'Back'
  end

  test "should edit Google tag manager Transport Settings" do
    transport_settings_google_tag_manager = FactoryBot.create(:transport_settings_google_tag_manager, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {container_id: @tsgoogletagmanager.container_id})           
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for Google Tag Manager was successfully updated.")
    assert page.has_content?(@tsgoogletagmanager.container_id)
  end

  test "should see Google analytics Transport Settings" do
    transport_settings_google_analytics = FactoryBot.create(:transport_settings_google_analytics, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Google Analytics")
    click_link_or_button 'Back'
  end

  test "should edit Google analytics Transport Settings" do
    transport_settings_google_analytics = FactoryBot.create(:transport_settings_google_analytics, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {tracking_id: @tsgoogleanalytics.tracking_id})           
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for Google Analytics was successfully updated.")
    assert page.has_content?(@tsgoogleanalytics.container_id)
  end 

  test "should see Store Transport Settings" do
    transport_settings_mailchimp = FactoryBot.create(:transport_settings_store, :club_id => @club.id)
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?("Store")
    click_link_or_button 'Back'
  end 

  test "should edit Store Transport Settings" do
    transport_settings_store = FactoryBot.create(:transport_settings_store, :club_id => @club.id)    
    visit transport_settings_path(@partner_prefix, @club.name)
    within("#transport_settings_table") do
      click_link_or_button 'Edit'
    end
    fill_in_form(nil, {url: @tsstore.url, api_token: @tsstore.api_token})           
    click_link_or_button 'Update Transport setting'
    assert page.has_content?("The transport setting for Store was successfully updated.")
    assert page.has_content?(@tsstore.url)
    assert page.has_content?(@tsstore.api_token)
  end
end




