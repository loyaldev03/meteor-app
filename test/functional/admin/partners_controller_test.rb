require 'test_helper'
      
class Admin::PartnersControllerTest < ActionController::TestCase
  setup do    
    @agent = FactoryGirl.create(:agent)
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
  end

  test "Admin should get index" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
        get :index
        assert_response :success
    end
  end

  test "Agents that should not get index" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :index
        assert_response :unauthorized
      end
    end
  end

  test "Admin should get new" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)    
      get :new
      assert_response :success
    end
  end

  test "Agents should not get new" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :new
        assert_response :unauthorized
      end
    end
  end

  test "Admin should create partner" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent) 
      partner = FactoryGirl.build(:partner)
      assert_difference('Partner.count') do
        post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
      end
      assert_redirected_to admin_partner_path(assigns(:partner))
    end
  end

  test "Agents that should not create partner" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        partner = FactoryGirl.build(:partner)
        post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
        assert_response :unauthorized
      end
    end
  end

  test "Admin should show partner" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent)
      get :show, id: @partner.id
      assert_response :success
    end
  end

  test "Agents should not show partner" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, id: @partner.id
        assert_response :unauthorized
      end
    end
  end

  test "Admin should get edit" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent)
      get :edit, id: @partner
      assert_response :success
    end
  end

  test "Agents should not get edit" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :edit, id: @partner.id
        assert_response :unauthorized
      end
    end
  end

  test "Admin should update partner" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent)
      put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                            :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                            :description => @partner.description }
      assert_redirected_to admin_partner_path(assigns(:partner))
    end
  end

  test "Agents should not update partner" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                              :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                              :description => @partner.description }
        assert_response :unauthorized
      end
    end
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "agent with club roles should not should not get index" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :index
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get new" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :new
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not create partner" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    partner = FactoryGirl.build(:partner)
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get show partner" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @partner.id
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get edit partner" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, id: @partner.id
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not update partner" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
      assert_response :unauthorized
    end
  end
end
