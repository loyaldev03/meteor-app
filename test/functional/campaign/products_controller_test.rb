require 'test_helper'

class Campaigns::ProductsControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )       
    @product = FactoryGirl.create(:random_product, :club_id => @club.id)
    @campaign.products << @product  
  end

  def sign_agent_with_global_role(type)
     @agent = FactoryGirl.create type
     sign_in @agent     
  end

  def sign_agent_with_club_role(type, role)
    @agent = FactoryGirl.create(type, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
    sign_in @agent
  end

  test "agents that should show products assign to campaign" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :show, partner_prefix: @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not show products assign to campaign" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        get :show, partner_prefix: @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "Agents that should get available products" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :available, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not get available products" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :available, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "Agents that should get assigned products" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :assigned, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not get assigned products" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :assigned, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "Agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "Agents that should assign products" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      put :assign, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not assign products" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        put :assign, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end  
  end

  test "Agents that should remove assigned products" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      delete :destroy, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not remove assigned products" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        delete :destroy, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end  
  end

  test "Agents that should edit labels of products assigned" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit_label, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not edit labels of products assigned" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :edit_label, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end  
  end

  test "Agents that should label assigned products" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      put :label, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
      assert_response :success, "Agent #{agent} can not access to this page."
    end 
  end

  test "agents that should not label assigned products" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        put :label, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end  
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test 'agent with club Admin role that should show products assign to campaign' do
    sign_agent_with_club_role(:agent,'admin')
    get :show, partner_prefix: @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
    assert_response :success, "Agent admin can not access to this page."       
  end

  test "agent with club roles that that should not show products assign to campaign" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :show, partner_prefix: @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should get available products" do
    sign_agent_with_club_role(:agent,'admin')
    get :available, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
    assert_response :success, "Agent admin can not access to this page."    
  end

  test "agent with club roles that should not get available products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :available, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should get assigned products" do
    sign_agent_with_club_role(:agent,'admin')
    get :assigned, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
    assert_response :success, "Agent admin can not access to this page."  
  end

  test "agent with club roles that should not get assigned products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :assigned, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should get edit" do
    sign_agent_with_club_role(:agent,'admin')
    get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
    assert_response :success, "Agent admin can not access to this page."  
  end

  test "agent with club roles that should not get edit" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should assign products" do
    sign_agent_with_club_role(:agent,'admin')
    put :assign, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
    assert_response :success, "Agent admin can not access to this page."  
  end

  test "agent with club roles that should not assign products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        put :assign, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should remove assigned products" do
    sign_agent_with_club_role(:agent,'admin')
    delete :destroy, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
    assert_response :success, "Agent admin can not access to this page."  
  end

  test "agent with club roles that should not remove assigned products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        delete :destroy, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should edit labels of products assigned" do
    sign_agent_with_club_role(:agent,'admin')
    get :edit_label, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
    assert_response :success, "Agent admin can not access to this page."      
  end

  test "agent with club roles that should not edit labels of products assigned" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :edit_label, product_id: @product.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agent with club Admin role that should label assigned products" do
    sign_agent_with_club_role(:agent,'admin')
    put :label, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
    assert_response :success, "Agent admin can not access to this page."     
  end

  test "agent with club roles that should not label assigned products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        put :label, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :campaign_id => @campaign.id, :format => :json
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end
end

