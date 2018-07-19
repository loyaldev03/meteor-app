require 'test_helper'

class PreferencesControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @preference_group = FactoryBot.create(:preference_group, :club_id => @club.id) 
    @preference = FactoryBot.create(:preference, :preference_group_id => @preference_group.id)  
  end

  test 'agents that should get index' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
      assert_response :success, "Agent #{agent} can not access to this page."
    end    
  end

  test "agents that should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "agents that should create preferences" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      

      assert_difference('Preference.count',1) do
        post :create, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id, preference: { name: preference.name } 
      end
      assert_response :success, "Agent #{agent} can not access to this page."      
    end
  end

  test "agents that should not create preferences" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
        post :create, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id, preference: { name: preference.name } 
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, id: @preference.id, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id      
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        get :edit, id: @preference.id, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id      
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test "agents that should update preferences" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
      put :update, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id , preference: { name: preference.name }
      assert_response :success, "Agent #{agent} can not update preferences."      
    end
  end

  test "agents that should not update preferences" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
        put :update, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id , preference: { name: preference.name }
        assert_response :unauthorized, "Agent #{agent} can update preferences."
      end
    end
  end

  test "should destroy preference" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      assert_difference('Preference.count', -1) do
        delete :destroy, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
        assert_response :success, "Agent #{agent} can not delete preferences." 
      end
    end         
  end

  test "agents that should not delete preferences" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        delete :destroy, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
        assert_response :unauthorized, "Agent #{agent} can delete preferences."
      end
    end
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test 'agent with club Admin role that should get index' do
    sign_agent_with_club_role(:agent,'admin')
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
    assert_response :success, "Agent admin can not access to this page."       
  end

  test "agent with club roles that should not get index" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should create preferences with club roles" do
    sign_agent_with_club_role(:agent, 'admin') 
    preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
    assert_difference('Preference.count',1) do
      post :create, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id, preference: { name: preference.name } 
    end
    assert_response :success, "Agent admin can not access to this page."      
  end

  test "agents that should not create preferences with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do       
        preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
        post :create, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id, preference: { name: preference.name } 
        assert_response :unauthorized, "Agent #{role} can access to this page." 
      end
    end
  end

  test "agents that should get edit with club roles" do
    sign_agent_with_club_role(:agent, 'admin')      
    get :edit, id: @preference.id, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id      
    assert_response :success, "Agent admin can not access to this page."    
  end

  test "agents that should not get edit with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do 
        get :edit, id: @preference.id, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id      
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should update preferences with club roles" do
    sign_agent_with_club_role(:agent, 'admin')
    preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
    put :update, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id , preference: { name: preference.name }
    assert_response :success, "Agent admin can not update preferences."       
  end

  test "agents that should not update preferences with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do 
        preference = FactoryBot.build(:preference, :preference_group_id => @preference_group.id)      
        put :update, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id , preference: { name: preference.name }
        assert_response :unauthorized, "Agent #{role} can update preferences."
      end
    end
  end

  test "agent with club Admin role that should NOT get index, edit when it allows to another club" do    
    another_club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    agent = FactoryBot.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: another_club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
    assert_response :unauthorized     
    get :edit, id: @preference.id, partner_prefix: @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id      
    assert_response :unauthorized  
    sign_out agent  
  end

  test "should destroy preference with club roles" do
    sign_agent_with_club_role(:agent, 'admin')
    assert_difference('Preference.count', -1) do
      delete :destroy, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
      assert_response :success, "Agent admin can not delete preferences." 
    end      
  end

  test "agents that should not delete preferences with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do   
        delete :destroy, :id => @preference.id, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :preference_group_id => @preference_group.id
        assert_response :unauthorized, "Agent #{role} can delete preferences."
      end
    end
  end
end