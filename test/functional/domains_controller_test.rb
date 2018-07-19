require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  
  def setup
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @domain = FactoryBot.create(:domain, :partner_id => @partner.id, :club_id => @club.id)
    @agent = FactoryBot.create(:agent)
    @partner_prefix = @partner.prefix
  end

  test "agents that should get index" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      get :index, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "agents that should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent     
      perform_call_as(@agent) do
        get :index, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "agents that should get new" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      get :new, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "agents that sould not get new" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "agents that should create domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      domain = FactoryBot.build(:domain, :partner_id => @partner.id )
      assert_difference('Domain.count',1) do
        post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
          description: domain.description, hosted: domain.hosted, url: domain.url }
      end
      assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
    end
  end

  test "agents that should not create domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        domain = FactoryBot.build(:domain, :partner_id => @partner.id )
        post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
            description: domain.description, hosted: domain.hosted, url: domain.url } 
        assert_response :unauthorized
      end
    end
  end

  test "agents that should show domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      get :show, id: @domain.id, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "agents that should not show domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :show, id: @domain.id, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end


  test "agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      get :edit, id: @domain, partner_prefix: @partner_prefix
      assert_response :success
    end
  end

  test "agents that should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :edit, id: @domain, partner_prefix: @partner_prefix
        assert_response :unauthorized
      end
    end
  end

  test "agents that should update domain" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryBot.create agent
      sign_in @agent
      put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
      assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
    end
  end

  test "agents that should not update domain" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
        assert_response :unauthorized
      end
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

  test "agent with club roles should not get index" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :index, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get index" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :index, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not get new" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :new, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get new" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :index, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not create domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    domain = FactoryBot.build(:domain, :partner_id => @partner.id )
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
                    description: domain.description, hosted: domain.hosted, url: domain.url }
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should create domain only for it's club" do
    sign_in(@agent)
    club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    club2 = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    domain = FactoryBot.build(:domain)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    assert_difference("Domain.count") do
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
                      description: domain.description, hosted: domain.hosted, url: domain.url, club_id: @club.id }
    end
    post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
                    description: domain.description, hosted: domain.hosted, url: domain.url, club_id: club2.id }
    assert_response :unauthorized
  end

  test "agent with club roles should not get show domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :show, id: @domain.id, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get show domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not get edit domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, id: @domain, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should get edit domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    get :edit, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "agent with club roles should not update domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
      assert_response :unauthorized
    end
  end

  test "agent with club role admin should update domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
  end

  test "agent with club roles should not destroy domain" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      delete :destroy, id: @domain, partner_prefix: @partner_prefix
      assert_response :unauthorized
    end
  end
 end
