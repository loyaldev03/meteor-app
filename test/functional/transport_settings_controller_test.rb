require 'test_helper'

class TransportSettingsControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)     
    @tsmailchimp = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id)
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


  test "agents that should get index" do 
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do   
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."     
      end
    end
  end

  test "agents that should show transport settings" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)      
      get :show, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not show campaigns" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        get :show, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "agents that should get new" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not get new" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test "agents that should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        get :edit, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test "agents that should create transport setting" do
    [:confirmed_admin_agent].each do |agent|            
      transportSetting = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)    
      sign_agent_with_global_role(agent)
      assert_difference('TransportSetting.count',1) do        
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: {
          transport: transportSetting.transport, client_id: transportSetting.client_id, 
          client_secret: transportSetting.client_secret, access_token: transportSetting.access_token
        }  
      end
      transportsettingcreated = TransportSetting.find_by club_id: @club.id, transport: TransportSetting.transports['facebook']  
      assert_redirected_to transport_setting_path(assigns(:transportSetting), partner_prefix: @partner_prefix, :club_prefix => @club.name, :id => transportsettingcreated.id )
    end
  end

  test "agents that should not create transport setting" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        transportSetting = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)    
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: {
          transport: transportSetting.transport, client_id: transportSetting.client_id, 
          client_secret: transportSetting.client_secret, access_token: transportSetting.access_token
        }       
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "agents that should update transport settings" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      @club1 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
      transportSetting = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club1.id)       
      put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: { api_key: transportSetting.api_key }
      assert_redirected_to transport_setting_path(assigns(:transportSetting), partner_prefix: @partner_prefix, :club_prefix => @club.name, :id => @tsmailchimp.id )
    end
  end

  test "agents that should not update campaign" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @club1 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) 
        transportSetting = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club1.id)       
        put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: { api_key: transportSetting.api_key }
        assert_response :unauthorized, "Agent #{agent} can update this page."
      end
    end
  end

  ####################################################
  #  CLUBS ROLES
  #################################################### 

  test "agent with club Admin role that should get index" do     
    sign_agent_with_club_role(:agent,'admin')
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success, "Agent with club admin role can not access to this page."
  end

  test "agent with club Admin role that should NOT get index, show, new, edit when it allows to another club" do    
    another_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: another_club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized 
    get :show, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :unauthorized
    get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :unauthorized
    get :edit, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name          
    assert_response :unauthorized  
    sign_out agent  
  end

  test "agent with club roles that should not get index" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do     
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should show campaigns with club roles" do
    sign_agent_with_club_role(:agent, 'admin')
    get :show, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "agents that should not show campaigns with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do 
        get :show, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{role} can update this page."
      end
    end
  end

  test "agents that should get new with club roles" do
    sign_agent_with_club_role(:agent, 'admin')
    get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :success, "Agent admin can not access to this page."
  end

  test "agents that should not get new with club roles" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should create transport setting with club roles" do
    sign_agent_with_club_role(:agent, 'admin')
    transportSetting = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)        
    assert_difference('TransportSetting.count',1) do        
      post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: {
        transport: transportSetting.transport, client_id: transportSetting.client_id, 
        client_secret: transportSetting.client_secret, access_token: transportSetting.access_token
      }  
    end
    transportsettingcreated = TransportSetting.find_by club_id: @club.id, transport: TransportSetting.transports['facebook']  
    assert_redirected_to transport_setting_path(assigns(:transportSetting), partner_prefix: @partner_prefix, :club_prefix => @club.name, :id => transportsettingcreated.id )
  end

  test "agents that should not create transport setting with club roles" do    
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        transportSetting = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)    
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: {
          transport: transportSetting.transport, client_id: transportSetting.client_id, 
          client_secret: transportSetting.client_secret, access_token: transportSetting.access_token
        }       
        assert_response :unauthorized, "Agent #{role} can access to this page." 
      end
    end
  end

  test "agents that should get edit with club role" do
    sign_agent_with_club_role(:agent, 'admin')
    get :edit, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
    assert_response :success, "Agent admin can not access to this page."    
  end

  test "agents that should not get edit with club role" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :edit, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test "agents that should update campaign with club role" do
    sign_agent_with_club_role(:agent, 'admin')
    @club1 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    transportSetting = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club1.id)       
    put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: { api_key: transportSetting.api_key }
    assert_redirected_to transport_setting_path(assigns(:transportSetting), partner_prefix: @partner_prefix, :club_prefix => @club.name, :id => @tsmailchimp.id )
  end

  test "agents that should not update campaign with club role" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        @club1 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) 
        transportSetting = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club1.id)       
        put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transport_setting: { api_key: transportSetting.api_key }
        assert_response :unauthorized, "Agent #{role} can update this page."
      end
    end
  end
end