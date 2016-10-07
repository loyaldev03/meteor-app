require 'test_helper' 

class CampaignTest < ActionDispatch::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)    
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
  end

  def login_general_admin(type)
    @admin_agent = FactoryGirl.create(type)
    sign_in_as(@admin_agent)
  end

  def fill_in_form(unsaved_campaign, campaign_type, transport)
    fill_in 'campaign[name]', with: unsaved_campaign.name
    fill_in 'campaign[landing_name]', with: unsaved_campaign.landing_name   
    first("#select2-campaign_terms_of_membership_id-container").click 
    find(:xpath, "//body").find(".select2-search__field").set(@terms_of_membership.name) 
    find(:xpath, "//body").find(".select2-results__option--highlighted").click 
    fill_in 'campaign[enrollment_price]', with: unsaved_campaign.enrollment_price   
    select_from_datepicker("campaign_initial_date", unsaved_campaign.initial_date)
    select_from_datepicker("campaign_finish_date", unsaved_campaign.finish_date)
    select(campaign_type.capitalize, from: "campaign[campaign_type]")
    select(transport.capitalize, from: 'campaign[transport]')
    fill_in 'campaign[transport_campaign_id]', with: unsaved_campaign.transport_campaign_id
    fill_in 'campaign[utm_content]', with: unsaved_campaign.utm_content
    fill_in 'campaign[audience]', with: unsaved_campaign.audience   
  end

  test "create campaign" do    
    unsaved_campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)
    campaign_type = unsaved_campaign.campaign_type
    transport = unsaved_campaign.transport

    login_general_admin(:confirmed_admin_agent)
    visit campaigns_path(@partner.prefix, @club.name)
    click_link_or_button 'New Campaign'   
    fill_in_form(unsaved_campaign, campaign_type, transport)    
    click_link_or_button 'Create Campaign'
    assert page.has_content?("The campaign #{unsaved_campaign.name} was successfully created.")
  end

  test "should show campaign" do
    campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )  
    login_general_admin(:confirmed_admin_agent)
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?(campaign.name)
    assert page.has_content?(campaign.campaign_type)
    assert page.has_content?(@terms_of_membership.name)
    assert page.has_content?(campaign.enrollment_price)
    assert page.has_content?(campaign.transport)
    assert page.has_content?(campaign.transport_campaign_id)
    assert page.has_content?(campaign.utm_medium)
    assert page.has_content?(campaign.utm_content)
    assert page.has_content?(campaign.audience)   
  end

  test "should not update campaigns in the past when it has campaign_days created" do
    campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id, :initial_date => Time.zone.yesterday)  
    campaign_days = FactoryGirl.create(:campaign_day, :campaign_id => campaign.id)
    login_general_admin(:confirmed_admin_agent)
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Edit'
    end
    select_from_datepicker("campaign_initial_date", campaign.initial_date - 3.days)
    select_from_datepicker("campaign_finish_date", campaign.finish_date - 1.days)
    click_link_or_button 'Update Campaign'
    assert page.has_content?("Campaign #{campaign.name} was not updated.")    
  end

  test "should only update name, initial_date and finish_date fields on campaign" do
    campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )  
    login_general_admin(:confirmed_admin_agent)
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Edit'
    end   
    assert page.has_css?("#campaign_landing_name[disabled]")
    assert page.has_css?("#terms_of_membership[readonly]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_type[readonly]")
    assert page.has_css?("#transport[readonly]")
    assert page.has_css?("#campaign_utm_medium[readonly]")
    assert page.has_css?("#campaign_transport_campaign_id[disabled]")
    assert page.has_css?("#campaign_utm_content[disabled]")
    assert page.has_css?("#campaign_audience[disabled]")
    assert page.has_css?("#campaign_campaign_code[disabled]")   

    unsaved_campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)
    fill_in 'campaign[name]', with: unsaved_campaign.name
    select_from_datepicker("campaign_initial_date", unsaved_campaign.initial_date + 3.days)
    select_from_datepicker("campaign_finish_date", unsaved_campaign.finish_date + 10.days)
    click_link_or_button 'Update Campaign'
    assert page.has_content?("Campaign #{unsaved_campaign.name} was updated succesfully.")
  end

  test "should display subscription_plan and enrollment_price disabled when campaign_type is Newsletter or Store promotion" do   
    login_general_admin(:confirmed_admin_agent)
    visit campaigns_path(@partner.prefix, @club.name)
    click_link_or_button 'New Campaign' 
    select('Newsletter', from: "campaign[campaign_type]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_terms_of_membership_id[disabled]")

    select('Store promotion', from: "campaign[campaign_type]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_terms_of_membership_id[disabled]")
  end
end