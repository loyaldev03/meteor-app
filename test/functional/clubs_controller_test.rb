require 'test_helper'

class ClubsControllerTest < ActionController::TestCase
  def setup    
    @agent = FactoryBot.create(:agent)
    @partner = FactoryBot.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Admin should get index" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :index, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "Agents should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do  
        get :index, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "Admin should get new" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :new, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "Agents should not get new" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "Admin should create club" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      @club = FactoryBot.build(:club, :partner_id => @partner.id)
      assert_difference('Club.count') do
        post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name, cs_phone_number: @club.cs_phone_number, cs_email: @club.cs_email }
      end
      assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
    end
  end

  test "Agents should not create club" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @club = FactoryBot.build(:club, :partner_id => @partner.id)
        post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
        assert_response :unauthorized
      end
    end
  end

  test "Admin should show club" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :show, id: @club, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "Agents should not show club" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, id: @club, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "Admin should get edit" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, id: @club, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "Agents should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :edit, id: @club, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "Admin should update club" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
      assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
    end
  end

  test "Agents should not update club" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
        assert_response :unauthorized
      end
    end
  end

  test "Admin should destroy club" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      assert_difference('Club.count', -1) do
        delete :destroy, id: @club, partner_prefix: @partner_prefix
      end
      assert_redirected_to clubs_path      
    end
  end

  test "Agents should not destroy club" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        delete :destroy, id: @club, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "agent with club roles should not should not get index" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :index, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get new" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :new, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not create club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_second = FactoryBot.build(:club, :partner_id => @partner.id)
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner_prefix, club: { description: club_second.description, name: club_second.name }    
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get show club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @club, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get edit club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :show, id: club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not update club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      club_role.role = role
      club_role.save
      put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should update club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    put :update, id: club.id, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :success
  end

  test "agent with club roles should not destroy club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      delete :destroy, id: club.id, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end
end