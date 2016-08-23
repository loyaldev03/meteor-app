require 'test_helper'

class TransportSettingsControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) 
    @tsmailchimp = TransportSetting.create(:transport => 1, :club_id => @club.id, :api_key => 'dfadfas34343')
    #FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id)
  end

  def sign_agent_with_global_role(type)
     @agent = FactoryGirl.create type
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

  test "agents that should create campaign" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      transportSetting = TransportSetting.new(:transport => 0, :club_id => @club.id, :client_id => '994106',:client_secret => 'f54adccaae4e24',:access_token => 'hYNzoP')
      assert_difference('TransportSetting.count',1) do
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transportSetting: {
          client_id: transportSetting.client_id, client_secret: transportSetting.client_secret, 
          access_token: transportSetting.access_token
        }    
      end
      assert_redirected_to transport_setting_path(assigns(:transportSetting), partner_prefix: @partner_prefix, :club_prefix => @club.name)
    end
  end

  test "agents that should not create campaign" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        transportSetting = TransportSetting.new(:transport => 0, :club_id => @club.id, :client_id => '994106',:client_secret => 'f54adccaae4e24',:access_token => 'hYNzoP')        
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, transportSetting: {
        client_id: transportSetting.client_id, client_secret: transportSetting.client_secret, 
        access_token: transportSetting.access_token
        }        
        assert_response :unauthorized, "Agent #{agent} can access to this page." 
      end
    end
  end

  test "agents that should update transport settings" do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      @club1 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) 
      transportSetting = TransportSetting.new(:transport => 1, :club_id => @club1.id, :api_key => 'dfadfas34343')      
      put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transportsetting: { api_key: transportSetting.settings }
      assert_redirected_to transport_setting_path
    end
  end

  test "agents that should not update campaign" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        transportSetting = TransportSetting.new(:transport => 1, :club_id => @club1.id, :api_key => 'dfadfas34343')      
        put :update, id: @tsmailchimp.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, transportsetting: { api_key: transportSetting.settings }      
        assert_response :unauthorized, "Agent #{agent} can update this page."
      end
    end
  end
end