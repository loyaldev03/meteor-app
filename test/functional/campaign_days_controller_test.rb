require 'test_helper'

class CampaignDaysControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )       
    @missing_campaign_days = FactoryGirl.create(:missing_campaign_day, :campaign_id => @campaign.id)
  end

  test "agents that should get missing campaign_days" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :missing, :partner_prefix => @partner.prefix, :club_prefix => @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end    
  end

  test "agents that should not get missing campaign_days" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :missing, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "agents that should get edit missing campaign_days" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not get edit missing campaign_days" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :edit, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "agents that should complete data on missing campaign_days" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)      
      put :update, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign_day: { spent: 302, converted: 36365, reached: 1630}
      assert_response :success, "Agent #{agent} can not update data on this page."     
    end
  end

  test "agents that should not complete data on missing campaign_days" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        put :update, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign_day: { spent: 302, converted: 36365, reached: 1630}
        assert_response :unauthorized, "Agent #{agent} can update this page."     
      end
    end
  end

  #####################################################
  # CLUBS ROLES
  #####################################################   

  test "agent with club Admin role that should get missing campaign_days" do     
    sign_agent_with_club_role(:agent,'admin')
    get :missing, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success, "Agent admin can not access to this page."    
  end

  test "agent with club roles that should not get missing campaign_days" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :missing, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should get edit missing campaign_days with club role" do
    sign_agent_with_club_role(:agent, 'admin')
    get :edit, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
    assert_response :success, "Agent admin can not access to this page."    
  end

  test "agents that should not get edit missing campaign_days with club role" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :edit, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should complete data on missing campaign_days with club role" do
    sign_agent_with_club_role(:agent, 'admin')    
    put :update, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign_day: { spent: 302, converted: 36365, reached: 1630}
    assert_response :success, "Agent admin can not update data on this page."      
  end

  test "agents that should not complete data on missing campaign_days club role" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do        
        put :update, id: @missing_campaign_days.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign_day: { spent: 302, converted: 36365, reached: 1630}
        assert_response :unauthorized, "Agent #{role} can update data to this page."
      end
    end
  end
end

  