require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  def setup
    @partner = FactoryGirl.create(:partner)
    @domain = FactoryGirl.create(:domain, :partner_id => @partner.id)
    @agent = FactoryGirl.create(:agent)
    @partner_prefix = @partner.prefix
  end

  test "agents that should get index" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agents that should get new" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :new, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not get new" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :new, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agents that should create domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
      assert_difference('Domain.count',1) do
        post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
          description: domain.description, hosted: domain.hosted, url: domain.url }
      end
      assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not create domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
          description: domain.description, hosted: domain.hosted, url: domain.url } 
      assert_response :unauthorized
    end
  end

  test "agents that should show domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :show, id: @domain.id, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not show domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :show, id: @domain.id, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end


  test "agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :edit, id: @domain, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :edit, id: @domain, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agents that should update domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
      assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
    end
  end

  #Profile fulfillment_managment
  test "agents that sould not update domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
      assert_response :unauthorized
    end
  end

  # test "should destroy domain" do
  #   assert_difference('Domain.count', -1) do
  #     delete :destroy, id: @domain.id, partner_prefix: @partner_prefix
  #   end
  #   assert_redirected_to domains_path
  # end



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

  test "agent with club roles should not create domain" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
                    description: domain.description, hosted: domain.hosted, url: domain.url }
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get show domain" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @domain.id, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not get edit domain" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, id: @domain, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not update domain" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
      assert_response :unauthorized
    end
  end

  test "agent with club roles should not destroy domain" do
    sign_in(@agent)
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      delete :destroy, id: @domain, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end
 end
