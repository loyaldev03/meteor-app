require 'test_helper'

class CampaignTest < ActionDispatch::IntegrationTest
 
  setup do
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)     
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign_twitter, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )  
    @missing_campaign_days = FactoryGirl.create(:missing_campaign_day, :campaign_id => @campaign.id)
  end

  def login_general_admin(type)
    @admin_agent = FactoryGirl.create(type)
    sign_in_as(@admin_agent)
  end

  def sign_agent_with_club_role(type, role)
    @agent = FactoryGirl.create(type, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
    sign_in_as(@agent) 
  end

  test "should enter values on missing campaign date - General Admin" do
    login_general_admin(:confirmed_admin_agent)
    visit missing_campaign_days_path(@partner.prefix, @club.name)
    within("#campaign_days_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'campaign_day[spent]', with: 302
    fill_in 'campaign_day[reached]', with: 36365
    fill_in 'campaign_day[converted]', with: 1630
    click_link_or_button 'Update Campaign day'
    assert page.has_content?("Campaign day #{@missing_campaign_days.date} for Campaign #{@campaign.name} was update successfuly. ")
  end

  test "should enter values on missing campaign date - Admin by club" do
    sign_agent_with_club_role(:agent, 'admin')    
    visit missing_campaign_days_path(@partner.prefix, @club.name)
    within("#campaign_days_table") do
      click_link_or_button 'Edit'
    end
    fill_in 'campaign_day[spent]', with: 302
    fill_in 'campaign_day[reached]', with: 36365
    fill_in 'campaign_day[converted]', with: 1630
    click_link_or_button 'Update Campaign day'
    assert page.has_content?("Campaign day #{@missing_campaign_days.date} for Campaign #{@campaign.name} was update successfuly. ")
  end
end