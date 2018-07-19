require 'test_helper'

class Admin::AgentsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @representative_user = FactoryBot.create(:confirmed_representative_agent)    
    @supervisor_user = FactoryBot.create(:confirmed_supervisor_agent)
    @api_user = FactoryBot.create(:confirmed_api_agent)
    @agent = FactoryBot.create(:agent)   
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

  test "Agents that should not get new" do
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

  test "Admin should create agent" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
        agent = FactoryBot.build(:confirmed_admin_agent)
        assert_difference('Agent.count', 1) do
          post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
        end
        assert_redirected_to admin_agent_path(assigns(:agent))
    end
  end

  test "Agents that should not create agent" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        agent = FactoryBot.build(:confirmed_admin_agent)
        assert_difference('Agent.count', 0) do
          post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
        end
        assert_response :unauthorized
      end
    end
  end

  test "Admin should show agent" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)    
      get :show, id: @agent.id
      assert_response :success
    end
  end

  test "Agents that should not show agent" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, id: @agent.id
        assert_response :unauthorized
      end
    end    
  end

  test "Admin should get edit" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent)    
      get :edit, id: @agent
      assert_response :success
    end
  end

  test "Agents should not get edit" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :edit, id: @agent.id
        assert_response :unauthorized
      end
    end
  end

  test "Admin should update agent" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent) 
      put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
      assert_redirected_to admin_agent_path(assigns(:agent))
    end
  end

  test "Agents that should not update agent" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
      	put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
        assert_response :unauthorized
      end
    end
  end

  test "Admin should destroy agent" do
    [:confirmed_admin_agent].each do |agent|
    sign_agent_with_global_role(agent) 
      assert_difference('Agent.count', -1) do
        delete :destroy, id: @agent
      end
      assert_redirected_to admin_agents_path
    end
  end

  test "Representative should not destroy agent" do
    [:confirmed_landing_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        delete :destroy, id: @agent
        assert_response :unauthorized
      end
    end
  end

## Testing abilities related to views ## 

  test "Admin and supervisor should see the enroll button on user#index." do
  	[@admin_user,@supervisor_user].each do |agent|
	  	sign_in agent
	  	assert agent.can?(:enroll, User), "#{agent.roles} cant see user's enroll button on user#index."
    end
  end

  test "Representative and Api users should not see the enroll button on user#index." do
  	sign_in @representative_user
    ability = Ability.new(@api_user)
    assert ability.cannot?(:enroll, User), "#{@api_user.roles} can see user's enroll button on user#index."

    ability = Ability.new(@representative_user)
    assert ability.can?(:enroll, User), "#{@representative_user.roles} can see user's enroll button on user#index."
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  def prepare_agents_with_club_roles
    @agent_club_role_admin = FactoryBot.create(:agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.role = "admin"
    club_role.agent_id = @agent_club_role_admin.id
    club_role.save
    @agent_club_role_admin2 = FactoryBot.create(:agent)
    club2 = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club2.id
    club_role.role = "admin"
    club_role.agent_id = @agent_club_role_admin2.id
    club_role.save
  end

  test "agent with club roles different from admin should not should not get index" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :index
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not get new" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :new
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not create agent" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    agent = FactoryBot.build(:confirmed_admin_agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email }, club_roles_attributes: { "1" => { role:"api", club_id: @agent.clubs.first.id }}
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not get show" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @agent.id
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not get edit" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, id: @agent.id
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not update agent" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
      assert_response :unauthorized
    end
  end

  test "agent with club roles different from admin should not destroy agent" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      delete :destroy, id: @agent
      assert_response :unauthorized
    end
  end

  test "agent with club roles admin should get index" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    get :index
    assert_response :success
  end

  test "agent with club roles admin should not get new" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    get :new
    assert_response :success
  end

  test "agent with club roles admin should create agent" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    agent = FactoryBot.build(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @agent_club_role_admin.clubs.first.id
    club_role.role = "admin"
    assert_difference('Agent.count') do
      post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email }, club_roles_attributes: { "1" => { role:"api", club_id: @agent_club_role_admin.clubs.first.id }}
    end
    assert_redirected_to admin_agent_path(assigns(:agent))
  end

  test "agent with club roles admin should only get to show agents related to the same club (within club_roles)" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    get :show, id: @agent_club_role_admin.id
    assert_response :success
    get :show, id: @agent_club_role_admin2.id
    assert_response :unauthorized
  end

  test "agent with club roles admin should not get edit agents related to the same club (within club_roles)" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    get :edit, id: @agent_club_role_admin.id
    assert_response :success
    get :edit, id: @agent_club_role_admin2.id
    assert_response :unauthorized
  end

  test "agent with club roles admin should update agent" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    club_role = ClubRole.new :club_id => @agent_club_role_admin.clubs.first.id
    club_role.role = "admin"
    club_role.agent_id = @agent.id
    club_role.save
    put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_redirected_to admin_agent_path(assigns(:agent))
  end

  test "agent with club roles admin should destroy agent" do
    prepare_agents_with_club_roles
    sign_in(@agent_club_role_admin)
    club_role = ClubRole.new :club_id => @agent_club_role_admin.clubs.first.id
    club_role.role = "admin"
    club_role.agent_id = @agent.id
    club_role.save
    assert_difference('Agent.count', -1) do
      delete :destroy, id: @agent
    end
  end 
end