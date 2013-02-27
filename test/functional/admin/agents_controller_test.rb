require 'test_helper'

class Admin::AgentsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agent = FactoryGirl.create(:agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
  end

  test "Admin should get index" do
    sign_in @admin_user
    get :index
    assert_response :success
  end

  test "Representative should not get index" do
    sign_in @representative_user
    get :index
    assert_response :unauthorized
  end

  test "Fulfillment Manager should not get index" do
    sign_in @fulfillment_manager_user
    get :index
    assert_response :unauthorized
  end

  test "Supervisor should not get index" do
    sign_in @supervisor_user
    get :index
    assert_response :unauthorized
  end

  test "Api user should not get index" do
    sign_in @api_user
    get :index
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_manager user should not get index" do
    sign_in @fulfillment_manager_user
    get :index
    assert_response :unauthorized
  end

  test "Admin should get new" do
    sign_in @admin_user
    get :new
    assert_response :success
  end

  test "Representative should not get new" do
    sign_in @representative_user
    get :new
    assert_response :unauthorized
  end

  test "Supervisor should not get new" do
    sign_in @supervisor_user
    get :new
    assert_response :unauthorized
  end

  test "Api user should not get new" do
    sign_in @api_user
    get :new
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not get new" do
    sign_in @fulfillment_manager_user
    get :new
    assert_response :unauthorized
  end

  test "Admin should create agent" do
    sign_in @admin_user
    agent = FactoryGirl.build(:confirmed_admin_agent)
    assert_difference('Agent.count') do
      post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
    end
    assert_redirected_to admin_agent_path(assigns(:agent))
  end

  test "Representative should not create agent" do
    sign_in @representative_user
    agent = FactoryGirl.build(:confirmed_admin_agent)
    post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
    assert_response :unauthorized
  end

  test "Supervisor should not create agent" do
    sign_in @supervisor_user
    agent = FactoryGirl.build(:confirmed_admin_agent)
    post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
    assert_response :unauthorized
  end

  test "Api user should not create agent" do
    sign_in @api_user
    agent = FactoryGirl.build(:confirmed_admin_agent)
    post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not create agent" do
    sign_in @fulfillment_manager_user
    agent = FactoryGirl.build(:confirmed_admin_agent)
    post :create, agent: { :username => agent.username, :password => agent.password, :password_confirmation => agent.password_confirmation, :email => agent.email, :roles => agent.roles }
    assert_response :unauthorized
  end

  test "Admin should show agent" do
    sign_in @admin_user
    get :show, id: @agent.id
    assert_response :success
  end

  test "Representative should not show agent" do
    sign_in @representative_user
    get :show, id: @agent.id
    assert_response :unauthorized
  end

  test "Supervisor should not show agent" do
    sign_in @supervisor_user
    get :show, id: @agent.id
    assert_response :unauthorized
  end

  test "Api user should not show agent" do
    sign_in @api_user
    get :show, id: @agent.id
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not show agent" do
    sign_in @fulfillment_manager_user
    get :show, id: @agent.id
    assert_response :unauthorized
  end  

  test "Admin should get edit" do
    sign_in @admin_user
    get :edit, id: @agent
    assert_response :success
  end

  test "Representative should not get edit" do
    sign_in @representative_user
    get :edit, id: @agent.id
    assert_response :unauthorized
  end

  test "Supervisor should not get edit" do
    sign_in @supervisor_user
    get :edit, id: @agent.id
    assert_response :unauthorized
  end

  test "Api user should not get edit" do
    sign_in @api_user
    get :edit, id: @agent.id
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not get edit" do
    sign_in @fulfillment_manager_user
    get :edit, id: @agent.id
    assert_response :unauthorized
  end

  test "Admin should update agent" do
    sign_in @admin_user
    put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_redirected_to admin_agent_path(assigns(:agent))
  end

  test "Representative should not update agent" do
    sign_in @representative_user
	put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_response :unauthorized
  end

  test "Supervisor should not update agent" do
    sign_in @supervisor_user
	put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_response :unauthorized
  end

  test "Api user should not update agent" do
    sign_in @api_user
	put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not update agent" do
    sign_in @fulfillment_manager_user
  put :update, id: @agent.id, agent: { :username => @agent.username, :password => @agent.password, :password_confirmation => @agent.password_confirmation, :email => @agent.email, :roles => @agent.roles }
    assert_response :unauthorized
  end

  test "Admin should destroy agent" do
    sign_in @admin_user
    assert_difference('Agent.count', -1) do
      delete :destroy, id: @agent
    end

    assert_redirected_to admin_agents_path
  end

  test "Representative should not destroy agent" do
    sign_in @representative_user
    delete :destroy, id: @agent
    assert_response :unauthorized
  end

  test "Supervisor should not destroy agent" do
    sign_in @supervisor_user
    delete :destroy, id: @agent
    assert_response :unauthorized
  end

  test "Api user should not destroy agent" do
    sign_in @api_user
    delete :destroy, id: @agent
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not destroy agent" do
    sign_in @fulfillment_manager_user
    delete :destroy, id: @agent
    assert_response :unauthorized
  end

## Testing abilities related to views ## 

  test "Admin and supervisor should see the enroll button on member#index." do
  	[@admin_user,@supervisor_user].each do |agent|
	  	sign_in agent
	  	assert agent.can?(:enroll, Member), "#{agent.roles} cant see member's enroll button on member#index."
    end
  end

  test "Representative and Api users should not see the enroll button on member#index." do
  	sign_in @representative_user
    ability = Ability.new(@api_user)
    assert ability.cannot?(:enroll, Member), "#{@api_user.roles} can see member's enroll button on member#index."

    ability = Ability.new(@representative_user)
    assert ability.can?(:enroll, Member), "#{@representative_user.roles} can see member's enroll button on member#index."
  end

end