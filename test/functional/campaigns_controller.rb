require 'test_helper'

class CampaignsControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
    @agent = FactoryGirl.create(:agent)    
    @partner_prefix = @partner.prefix
  end

  test "agents that should get index" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
      assert_response :success
    end
  end

  test "agents that should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  test "agents that should show campaigns" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :show, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :success
    end
  end

  test "agents that should not show campaigns" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :show, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  test "agents that should get new" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :success
    end
  end

  test "agents that should not get new" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  #@Sebas could you help me with this test case? It displays this error
  #ActionView::Template::Error: undefined method `map' for nil:NilClass
   # app/views/campaigns/_form.html.erb:85:in `_app_views_campaigns__form_html_erb___107854232981373658_57384440'
   # app/views/campaigns/new.html.erb:8:in `block in _app_views_campaigns_new_html_erb__4329571917558607088_57534560'
   # app/views/campaigns/new.html.erb:7:in `_app_views_campaigns_new_html_erb__4329571917558607088_57534560'
   # app/controllers/campaigns_controller.rb:32:in `create'
   # test/functional/campaigns_controller.rb:248:in `block (2 levels) in <class:CampaignsControllerTest>'
   # test/functional/campaigns_controller.rb:247:in `block in <class:CampaignsControllerTest>'


  test "agents that should create campaign" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      assert_difference('Campaign.count',1) do
        post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: {
          name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date,
           enrollment_price: campaign.enrollment_price, campaign_type: campaign.campaign_type,
           transport: campaign.transport, transport_campaign_id: campaign.transport_campaign_id,
           campaign_medium: campaign.campaign_medium, campaign_medium_version: campaign.campaign_medium_version,
           marketing_code: campaign.marketing_code, fulfillment_code: campaign.fulfillment_code,
           club_id: campaign.club_id, terms_of_membership: campaign.terms_of_membership.id
        }    
      end
      assert_redirected_to campaign_path(assigns(:campaign), partner_prefix: @partner_prefix, :club_prefix => @club.name)
    end
  end

  test "agents that should not create campaign" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: {
          name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date,
          enrollment_price: campaign.enrollment_price, campaign_type: campaign.campaign_type,
          transport: campaign.transport, transport_campaign_id: campaign.transport_campaign_id,
          campaign_medium: campaign.campaign_medium, campaign_medium_version: campaign.campaign_medium_version,
          marketing_code: campaign.marketing_code, fulfillment_code: campaign.fulfillment_code,
          club_id: campaign.club_id, terms_of_membership: campaign.terms_of_membership.id
        } 
      assert_response :unauthorized
    end
  end

  test "agents that should get edit" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :edit, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
      assert_response :success
    end
  end

  test "agents that should not get edit" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :edit, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
      assert_response :unauthorized
    end
  end

  test "agents that should update campaign" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      put :update, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: { name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date }
      assert_redirected_to campaigns_path     
    end
  end

  test "agents that should not update campaign" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      put :update, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: { name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date }
      assert_response :unauthorized
    end
  end

  test "agents should not delete campaigns" do
    [:confirmed_admin_agent, :confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent            
      begin
        delete :destroy, club_id: @club.id, id: @campaign.id
      rescue Exception => error
        assert (error.instance_of? ActionController::UrlGenerationError)
      end
    end
  end


  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "agent with club Admin role that should get index" do    
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success    
  end

  test "agent with club Admin role that should NOT get index, show,  when it allows to another club" do    
    another_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: another_club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized 
    get :show, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :unauthorized
    get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :unauthorized
    get :edit, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name          
    assert_response :unauthorized    
  end

  test "agent with club roles that should not get index" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  test "agents that should show campaigns with club roles" do
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :show, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :success

  end

  test "agents that should not show campaigns with club roles" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      get :show, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  test "agents that should get new with club roles" do
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "agents that should not get new with club roles" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      get :new, partner_prefix: @partner_prefix, :club_prefix => @club.name
      assert_response :unauthorized
    end
  end

  test "agents that should create campaign with club roles" do
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
    assert_difference('Campaign.count',1) do
      post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: {
        name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date,
         enrollment_price: campaign.enrollment_price, campaign_type: campaign.campaign_type,
         transport: campaign.transport, transport_campaign_id: campaign.transport_campaign_id,
         campaign_medium: campaign.campaign_medium, campaign_medium_version: campaign.campaign_medium_version,
         marketing_code: campaign.marketing_code, fulfillment_code: campaign.fulfillment_code,
         club_id: campaign.club_id, terms_of_membership: campaign.terms_of_membership.id
      } 
    end  
    assert_redirected_to campaign_path(assigns(:campaign), partner_prefix: @partner_prefix, :club_prefix => @club.name)    
  end

  test "agents that should not create campaign with club roles" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)

      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      post :create, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: {
          name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date,
          enrollment_price: campaign.enrollment_price, campaign_type: campaign.campaign_type,
          transport: campaign.transport, transport_campaign_id: campaign.transport_campaign_id,
          campaign_medium: campaign.campaign_medium, campaign_medium_version: campaign.campaign_medium_version,
          marketing_code: campaign.marketing_code, fulfillment_code: campaign.fulfillment_code,
          club_id: campaign.club_id, terms_of_membership: campaign.terms_of_membership.id
        } 
      assert_response :unauthorized
    end
  end

  test "agents that should get edit with club role" do
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :edit, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
    assert_response :success    
  end

  test "agents that should not get edit with club role" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      get :edit, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name      
      assert_response :unauthorized
    end
  end

  test "agents that should update campaign with club role" do
    agent = FactoryGirl.create(:confirmed_admin_agent, roles: '') 
    ClubRole.create(club_id: @club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
    put :update, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: { name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date }
    assert_redirected_to campaigns_path  
  end

  test "agents that should not update campaign with club role" do
    sign_in(@agent)
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      campaign = FactoryGirl.build(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )
      put :update, id: @campaign.id, partner_prefix: @partner_prefix, :club_prefix => @club.name, campaign: { name: campaign.name, initial_date: campaign.initial_date, finish_date: campaign.finish_date }
      assert_response :unauthorized
    end
  end

  test "agents should not delete campaigns with club roles" do
     sign_in(@agent)
    ['admin', 'supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)            
      begin
        delete :destroy, club_id: @club.id, id: @campaign.id
      rescue Exception => error
        assert (error.instance_of? ActionController::UrlGenerationError)
      end
    end
  end
end

