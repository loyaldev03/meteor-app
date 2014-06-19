require 'test_helper'

class ClubsControllerTest < ActionController::TestCase
  def setup
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_user = FactoryGirl.create(:confirmed_agency_agent)    
    @fulfillment_managment_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent) 
    @agent = FactoryGirl.create(:agent)
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Admin should get index" do
    sign_in @admin_user
    get :index, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get index" do
    sign_in @representative_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get index" do
    sign_in @supervisor_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get index" do
    sign_in @api_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Agency user should not get index" do
    sign_in @agency_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not get index" do
    sign_in @fulfillment_managment_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should get new" do
    sign_in @admin_user
    get :new, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get new" do
    sign_in @representative_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get new" do
    sign_in @supervisor_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get new" do
    sign_in @api_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Agency user should not get new" do
    sign_in @agency_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not get new" do
    sign_in @fulfillment_managment_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should create club" do
    sign_in @admin_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    assert_difference('Club.count') do
      post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name, cs_phone_number: @club.cs_phone_number }
    end
    assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
  end

  test "Representative should not create club" do
    sign_in @representative_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  test "Supervisor should not create club" do
    sign_in @supervisor_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }    
    assert_response :unauthorized
  end

  test "Api user should not create club" do
    sign_in @api_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }    
    assert_response :unauthorized
  end

  test "Agency user should not create club" do
    sign_in @agency_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }    
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not create club" do
    sign_in @fulfillment_managment_user
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }    
    assert_response :unauthorized
  end

  test "Admin should show club" do
    sign_in @admin_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not show club" do
    sign_in @representative_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not show club" do
    sign_in @supervisor_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not show club" do
    sign_in @api_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Agency user should not show club" do
    sign_in @agency_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not show club" do
    sign_in @fulfillment_managment_user
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should get edit" do
    sign_in @admin_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get edit" do
    sign_in @representative_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get edit" do
    sign_in @supervisor_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get edit" do
    sign_in @api_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Agency user should not get edit" do
    sign_in @agency_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not get edit" do
    sign_in @fulfillment_managment_user
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should update club" do
    sign_in @admin_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
  end

  test "Representative should not update club" do
    sign_in @representative_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  test "Supervisor should not update club" do
    sign_in @supervisor_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  test "Api user should not update club" do
    sign_in @api_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  test "Agency user should not update club" do
    sign_in @agency_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not update club" do
    sign_in @fulfillment_managment_user
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :unauthorized
  end

  test "Admin should destroy club" do
    sign_in @admin_user
    assert_difference('Club.count', -1) do
      delete :destroy, id: @club, partner_prefix: @partner_prefix
    end

    assert_redirected_to clubs_path
  end

  test "Representative should not destroy club" do
    sign_in @representative_user
    delete :destroy, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not destroy club" do
    sign_in @supervisor_user
    delete :destroy, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not destroy club" do
    sign_in @api_user
    delete :destroy, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Agency user should not destroy club" do
    sign_in @agency_user
    delete :destroy, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should not destroy club" do
    sign_in @fulfillment_managment_user
    delete :destroy, id: @club, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "agent with club roles should not should not get index" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :index, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get new" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :new, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not create club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_second = FactoryGirl.build(:club, :partner_id => @partner.id)
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner_prefix, club: { description: club_second.description, name: club_second.name }    
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get show club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @club, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get edit club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :show, id: club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not update club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should update club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    put :update, id: club.id, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_response :success
  end

  test "agent with club roles should not destroy club" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      delete :destroy, id: club.id, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end
end