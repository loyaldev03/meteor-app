require 'test_helper'
      
class Admin::PartnersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @agent = FactoryGirl.create(:agent)
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
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

  test "Supervisor should not get index" do
    sign_in @supervisor_user
    get :index
    assert_response :unauthorized
  end

  test "fulfillment_manager should not get index" do
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

  test "fulfillment_manager should not get new" do
    sign_in @fulfillment_manager_user
    get :new
    assert_response :unauthorized
  end

  test "Admin should create partner" do
    sign_in @admin_user
    partner = FactoryGirl.build(:partner)
    assert_difference('Partner.count') do
      post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
    end

    assert_redirected_to admin_partner_path(assigns(:partner))
  end

  test "Representative should not create partner" do
    sign_in @representative_user
    partner = FactoryGirl.build(:partner)
    post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
    assert_response :unauthorized
  end

  test "Supervisor should not create partner" do
    sign_in @supervisor_user
    partner = FactoryGirl.build(:partner)
    post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
    assert_response :unauthorized
  end

  test "fulfillment_manager should not create partner" do
    sign_in @fulfillment_manager_user
    partner = FactoryGirl.build(:partner)
    post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
    assert_response :unauthorized
  end

  test "Admin should show partner" do
    sign_in @admin_user
    get :show, id: @partner.id
    assert_response :success
  end

  test "Representative should not show partner" do
    sign_in @representative_user
    get :show, id: @partner.id
    assert_response :unauthorized
  end

  test "Supervisor should not show partner" do
    sign_in @supervisor_user
    get :show, id: @partner.id
    assert_response :unauthorized
  end

  test "fulfillment_manager should not show partner" do
    sign_in @fulfillment_manager_user
    get :show, id: @partner.id
    assert_response :unauthorized
  end

  test "Admin should get edit" do
    sign_in @admin_user
    get :edit, id: @partner
    assert_response :success
  end

  test "Representative should not get edit" do
    sign_in @representative_user
    get :edit, id: @partner.id
    assert_response :unauthorized
  end

  test "Supervisor should not get edit" do
    sign_in @supervisor_user
    get :edit, id: @partner.id
    assert_response :unauthorized
  end

  test "fulfillment_manager should not get edit" do
    sign_in @fulfillment_manager_user
    get :edit, id: @partner.id
    assert_response :unauthorized
  end

  test "Admin should update partner" do
    sign_in @admin_user
    put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
    assert_redirected_to admin_partner_path(assigns(:partner))
  end

  test "Representative should not update partner" do
    sign_in @representative_user
    put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
    assert_response :unauthorized
  end

  test "Supervisor should not update partner" do
    sign_in @supervisor_user
    put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
    assert_response :unauthorized
  end

  test "fulfillment_manager should not update partner" do
    sign_in @fulfillment_manager_user
    put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
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
      get :index
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
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
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
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
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
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
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
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @partner.id, partner: { :prefix => @partner_prefix, :name => @partner.name, 
                                          :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, 
                                          :description => @partner.description }
      assert_response :unauthorized
    end
  end
end
