require 'test_helper' 

class CampaignTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)    
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )      
    @preference_group = FactoryGirl.create(:preference_group, :club_id => @club.id)    
    sign_in_as(@admin_agent)
  end

  def fill_in_form(unsaved_campaign, campaign_type, transport)
    fill_in 'campaign[name]', with: unsaved_campaign.name
    fill_in 'campaign[landing_name]', with: unsaved_campaign.landing_name  
    first("#select2-campaign_terms_of_membership_id-container").click 
    find('body > .select2-container .select2-search input.select2-search__field').set(@terms_of_membership.name)      
    find(:xpath, "//body").find(".select2-results__option--highlighted").click     
    fill_in 'campaign[enrollment_price]', with: unsaved_campaign.enrollment_price   
    select_from_datepicker("campaign_initial_date", unsaved_campaign.initial_date)
    select_from_datepicker("campaign_finish_date", unsaved_campaign.finish_date)
    select(campaign_type.capitalize, from: "campaign[campaign_type]")
    select(transport.capitalize, from: 'campaign[transport]')
    select(unsaved_campaign.utm_medium, from: 'campaign[utm_medium]')
    fill_in 'campaign[transport_campaign_id]', with: unsaved_campaign.transport_campaign_id
    fill_in 'campaign[utm_content]', with: unsaved_campaign.utm_content    
    fill_in 'campaign[audience]', with: unsaved_campaign.audience  
    fill_in 'campaign[delivery_date]', with: unsaved_campaign.delivery_date 
    find(:xpath, "//body").find(".select2-search__field").set(@preference_group.name) 
    find(:xpath, "//body").find(".select2-results__option--highlighted").click  
  end

  def configure_checkout_pages(unsaved_campaign)
    fill_in 'campaign[css_style]', with: unsaved_campaign.css_style
    fill_in 'campaign[checkout_page_bonus_gift_box_content]', with: unsaved_campaign.checkout_page_bonus_gift_box_content
    fill_in 'campaign[checkout_page_footer]', with: unsaved_campaign.checkout_page_footer
    fill_in 'campaign[thank_you_page_content]', with: unsaved_campaign.thank_you_page_content
    fill_in 'campaign[duplicated_page_content]', with: unsaved_campaign.duplicated_page_content
    fill_in 'campaign[error_page_content]', with: unsaved_campaign.error_page_content
    fill_in 'campaign[result_page_footer]', with: unsaved_campaign.result_page_footer
  end

  test "create campaign" do    
    unsaved_campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)
    campaign_type = unsaved_campaign.campaign_type
    transport = unsaved_campaign.transport
    visit campaigns_path(@partner.prefix, @club.name)
    click_link_or_button 'New Campaign'   
    fill_in_form(unsaved_campaign, campaign_type, transport)    
    click_link_or_button 'Create Campaign'
    assert page.has_content?("The campaign #{unsaved_campaign.name} was successfully created.")
  end

  test "should show campaign" do       
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Show'
    end
    assert page.has_content?(@campaign.name)
    assert page.has_content?(@campaign.campaign_type)
    assert page.has_content?(@terms_of_membership.name)
    assert page.has_content?(@campaign.enrollment_price)
    assert page.has_content?(@campaign.transport)
    assert page.has_content?(@campaign.transport_campaign_id)
    assert page.has_content?(@campaign.utm_medium)
    assert page.has_content?(@campaign.utm_content)
    assert page.has_content?(@campaign.audience)   
  end

  test "should not update campaigns in the past when it has campaign_days created" do    
    campaign_days = FactoryGirl.create(:campaign_day, :campaign_id => @campaign.id)    
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Edit'
    end   
    select_from_datepicker("campaign_initial_date", @campaign.initial_date - 3.days) rescue NoMethodError 
    select_from_datepicker("campaign_finish_date", @campaign.finish_date - 1.days) rescue NoMethodError
    click_link_or_button 'Update Campaign'
    assert page.has_content?("Campaign #{@campaign.name} was not updated.")    
  end

  test "should only update name, initial_date, finish_date and source id fields on campaign" do        
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Edit'
    end   
    assert page.has_css?("#campaign_landing_name[disabled]")
    assert page.has_css?("#terms_of_membership[readonly]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_campaign_type[readonly]")
    assert page.has_css?("#transport[readonly]")
    assert page.has_css?("#campaign_utm_medium[disabled]")    
    assert page.has_css?("#campaign_utm_content[disabled]")
    assert page.has_css?("#campaign_audience[disabled]")
    assert page.has_css?("#campaign_campaign_code[disabled]")   

    unsaved_campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)
    fill_in 'campaign[name]', with: unsaved_campaign.name
    select_from_datepicker("campaign_initial_date", unsaved_campaign.initial_date + 3.days)
    select_from_datepicker("campaign_finish_date", unsaved_campaign.finish_date + 10.days)
    fill_in 'campaign[transport_campaign_id]', with: unsaved_campaign.transport_campaign_id
    click_link_or_button 'Update Campaign'
    assert page.has_content?("Campaign #{unsaved_campaign.name} was updated succesfully.")
  end

  test "should display subscription_plan and enrollment_price disabled when campaign_type is Newsletter or Store promotion" do       
    visit campaigns_path(@partner.prefix, @club.name)
    click_link_or_button 'New Campaign' 
    select('Newsletter', from: "campaign[campaign_type]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_terms_of_membership_id[disabled]")

    select('Store promotion', from: "campaign[campaign_type]")
    assert page.has_css?("#campaign_enrollment_price[disabled]")
    assert page.has_css?("#campaign_terms_of_membership_id[disabled]")
  end

  test 'assign preferences to campaign' do    
    visit campaigns_path(@partner.prefix, @club.name)
    within("#campaigns_table") do
      click_link_or_button 'Edit'
    end
    find(:xpath, "//body").find(".select2-search__field").set(@preference_group.name) 
    find(:xpath, "//body").find(".select2-results__option--highlighted").click
    click_link_or_button 'Update Campaign'
    assert page.has_content?("Campaign #{@campaign.name} was updated succesfully.")
  end

  test "configure and update checkout settings" do
    unsaved_campaign = FactoryGirl.build(:campaign_with_checkout_settings)
    @campaign1 = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )  
    visit campaign_path(@partner.prefix, @club.name, @campaign1.id)    
    click_link_or_button 'Checkout Settings'
    click_link_or_button 'Edit Settings'
    configure_checkout_pages(unsaved_campaign)
    click_link_or_button 'Update Campaign'

    assert page.has_content? "Checkout Pages Settings Set"
    assert page.has_content? unsaved_campaign.checkout_page_bonus_gift_box_content
    assert page.has_content? unsaved_campaign.checkout_page_footer
    assert page.has_content? unsaved_campaign.thank_you_page_content
    assert page.has_content? unsaved_campaign.duplicated_page_content
    assert page.has_content? unsaved_campaign.error_page_content
    assert page.has_content? unsaved_campaign.result_page_footer
  end
end