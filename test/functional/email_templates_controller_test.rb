# encoding: utf-8
require 'test_helper'

class EmailTemplatesControllerTest < ActionController::TestCase

  setup do
  	@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @agent = FactoryGirl.create(:agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
    @tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'TOM for Email Templates Test')
  end

  test 'Admin should get index' do
    sign_in @admin_agent
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
    assert_response :success
  end

  test 'Non Admin agents should not get index' do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end

  test 'Admin should get new' do
    sign_in @admin_agent
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
    assert_response :success
  end

  test 'Non Admin agents should not get new' do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
    	get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end

  test 'Admin should get create' do
  	@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_agent
    comm = FactoryGirl.build(:email_template, :terms_of_membership_id => @tom.id)
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: { 
      name: comm.name, client: comm.client, external_attributes: comm.external_attributes }
    assert_response :success
  end

  test 'Non Admin agents should not get create' do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      post :create, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end

  test 'Admin agents should get edit' do
    sign_in @admin_agent
    get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => @tom.email_templates.first.id
    assert_response :success
  end

  test 'Non Admin agents should not get edit' do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => @tom.email_templates.first.id
      assert_response :unauthorized
    end
  end

  # test 'Admin agents should get update' do

  # end

  test 'Non Admin agents should not get update' do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      put :update, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => @tom.email_templates.first.id
      assert_response :unauthorized
    end
  end

	test 'Do not allow enter user communication duplicate where it is not Pillar type - Logged by General Admin' do
		comm = EmailTemplate.where(:terms_of_membership_id => @tom.id, :template_type => 'birthday').first
		sign_in(@admin_agent)
    assert_difference("EmailTemplate.count",0) do
  		post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: { 
  			name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: 'birthday' }
  		assert_response :success  
    end
	end


  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test 'Do not allow to see users communications from another TOM where I do not have permissions' do
    @club2 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club2.id, :name => 'TOM for Email Templates Test2')
    @club_admin = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => @club2.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    et = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'pillar', days_after_join_date: 1, external_attributes: nil)
    et2 = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom2.id, :template_type => 'pillar', days_after_join_date: 1, external_attributes: nil)
    get :show, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => et.id
    assert_response :unauthorized
    get :show, :partner_prefix => @partner.prefix, :club_prefix => @club2.name, :terms_of_membership_id => @tom2.id, :id => et2.id
    assert_response :success
  end

  test 'Do not allow enter user communication duplicate - Logged by Admin_by_club' do
    comm = EmailTemplate.where(:terms_of_membership_id => @tom.id, :template_type => 'birthday').first
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = "admin"
    club_role.save
    sign_in(@agent)

    comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id)
    assert_difference("EmailTemplate.count",0) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: { 
        name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: 'birthday' }
      assert_response :success
    end
  end

  test 'agent with admin club role should get index' do
    @club2 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tom2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club2.id, :name => 'TOM for Email Templates Test')
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
    assert_response :success
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club2.name, :terms_of_membership_id => @tom2.id
    assert_response :unauthorized
  end

  test 'agent with club roles should not get index' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end

  test 'agent with admin club role should get new' do
    @club2 = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
    assert_response :success
  end

  test 'agent with club roles should not get new' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end

  test 'agent with admin club role should get create' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    comm = FactoryGirl.build(:email_template, :terms_of_membership_id => @tom.id)
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: { 
      name: comm.name, client: comm.client, external_attributes: comm.external_attributes }
    assert_response :success
  end

  test 'agent with club roles should not get create' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      post :create, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id
      assert_response :unauthorized
    end
  end


  test 'agent with admin club role should get edit' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => @tom.email_templates.first.id
    assert_response :success
  end

  test 'agent with club roles should not get edit' do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, :partner_prefix => @partner.prefix, :club_prefix => @club.name, :terms_of_membership_id => @tom.id, :id => @tom.email_templates.first.id
      assert_response :unauthorized
    end
  end
end