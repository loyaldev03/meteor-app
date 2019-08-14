require 'test_helper'

class EmailTemplatesControllerTest < ActionController::TestCase
  setup do
    @admin_agent  = FactoryBot.create(:confirmed_admin_agent)
    @agent        = FactoryBot.create(:agent)
    @partner      = FactoryBot.create(:partner)
    @club         = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @user         = FactoryBot.build(:user)
    @credit_card  = FactoryBot.build(:credit_card)
    @tom          = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'TOM for Email Templates Test')
  end

  test 'Admin should get index' do
    sign_in @admin_agent
    get :index, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
    assert_response :success
  end

  test 'Non Admin agents should not get index' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :index, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should get new' do
    sign_in @admin_agent
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
    assert_response :success
  end

  test 'Non Admin agents should not get new' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should get create' do
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    sign_in @admin_agent
    comm = FactoryBot.build(:email_template, terms_of_membership_id: @tom.id)
    assert_difference('EmailTemplate.count') do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
        name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: comm.template_type, days: comm.days
      }
    end
    assert_redirected_to terms_of_membership_email_templates_url(partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id)
  end

  test 'Non Admin agents should not get create' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
        assert_response :unauthorized
      end
    end
  end

  test 'Admin agents should get edit' do
    sign_in @admin_agent
    get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
    assert_response :success
  end

  test 'Non Admin agents should not get edit' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
        assert_response :unauthorized
      end
    end
  end

  test 'Admin agents should get testing communications' do
    sign_in @admin_agent
    get :test_communications, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
    assert_response :success
  end

  test 'Admin agents should send testing communications' do
    sign_in @admin_agent
    @saved_user = create_active_user(@tom, :active_user, nil, {}, created_by: @admin_user)
    @communication = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
    assert_difference('Communication.count', 0) do
      assert_difference('Operation.count', 0) do
        post :test_communications, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id, email_template_id: @communication.id, user_id: @saved_user.id
      end
    end
    assert_response :success
    assert @response.body.include? I18n.t('error_messages.testing_communication_send')
  end

  test 'Non Admin agents should not get testing communications' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        get :test_communications, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
        assert_response :unauthorized
      end
    end
  end

  test 'Non Admin agents should not send testing communications' do
    @communication = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        post :test_communications, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id, email_template_id: @communication.id
        assert_response :unauthorized
      end
    end
  end

  test 'Admin agents should not send testing communications to users from other club' do
    sign_in @admin_agent
    @saved_user = create_active_user(@tom, :active_user, nil, {}, created_by: @admin_user)
    @communication = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
    @club2 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club2.id, name: 'TOM for Email Templates Test2')
    @saved_user2 = create_active_user(@tom2, :active_user, nil, {}, created_by: @admin_user)

    post :test_communications, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id, email_template_id: @communication.id, user_id: @saved_user2.id
    assert_response :success
    assert @response.body.include? 'Member does not belong to same club as the Template.'
  end

  test 'Admin should update email_template' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      comm = FactoryBot.create(:email_template, terms_of_membership_id: @tom.id)
      comm1 = FactoryBot.build(:email_template, terms_of_membership_id: @tom.id)
      put :update, id: comm.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
        name: comm1.name, client: comm1.client, external_attributes: comm1.external_attributes, template_type: comm1.template_type, days: comm1.days
      }
      assert_redirected_to terms_of_membership_email_templates_url(partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id)
    end
  end

  test 'Non Admin agents should not get update' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        put :update, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
        assert_response :unauthorized
      end
    end
  end

  test 'Do not allow enter user communication duplicate where it is not Pillar type - Logged by General Admin' do
    comm = EmailTemplate.where(terms_of_membership_id: @tom.id, template_type: 'birthday').first
    sign_in(@admin_agent)
    assert_difference('EmailTemplate.count', 0) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
        name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: 'birthday'
      }
      assert_response :success
    end
  end

  #####################################################
  # CLUBS ROLES
  #####################################################

  test 'Do not allow to see users communications from another TOM where I do not have permissions' do
    @club2 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club2.id, name: 'TOM for Email Templates Test2')
    @club_admin = FactoryBot.create(:agent)
    club_role = ClubRole.new club_id: @club2.id
    club_role.agent_id = @club_admin.id
    club_role.role = 'admin'
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    et = FactoryBot.create(:email_template, terms_of_membership_id: @tom.id, template_type: 'pillar', days: 1, external_attributes: nil)
    et2 = FactoryBot.create(:email_template, terms_of_membership_id: @tom2.id, template_type: 'pillar', days: 1, external_attributes: nil)
    get :show, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: et.id
    assert_response :unauthorized
    get :show, partner_prefix: @partner.prefix, club_prefix: @club2.name, terms_of_membership_id: @tom2.id, id: et2.id
    assert_response :success
  end

  test 'Do not allow enter user communication duplicate - Logged by Admin_by_club' do
    comm = EmailTemplate.where(terms_of_membership_id: @tom.id, template_type: 'birthday').first
    @agent = FactoryBot.create(:agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    sign_in(@agent)

    comm = FactoryBot.create(:email_template, terms_of_membership_id: @tom.id)
    assert_difference('EmailTemplate.count', 0) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
        name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: 'birthday'
      }
      assert_response :success
    end
  end

  test 'agent with admin club role should get index' do
    @club2 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club2.id, name: 'TOM for Email Templates Test')
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :index, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
    assert_response :success
    get :index, partner_prefix: @partner.prefix, club_prefix: @club2.name, terms_of_membership_id: @tom2.id
    assert_response :unauthorized
  end

  test 'agent with club roles should not get index' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      club_role.role = role
      club_role.save
      get :index, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
      assert_response :unauthorized
    end
  end

  test 'agent with admin club role should get new' do
    @club2 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
    assert_response :success
  end

  test 'agent with club roles should not get new' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      club_role.role = role
      club_role.save
      get :new, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
      assert_response :unauthorized
    end
  end

  test 'agent with admin club role should get create' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    comm = FactoryBot.build(:email_template, terms_of_membership_id: @tom.id)
    assert_difference('EmailTemplate.count') do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
        name: comm.name, client: comm.client, external_attributes: comm.external_attributes, template_type: comm.template_type, days: comm.days
      }
    end
    assert_redirected_to terms_of_membership_email_templates_url(partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id)
  end

  test 'agent with club roles should not get create' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id
      assert_response :unauthorized
    end
  end

  test 'agent with admin club role should get edit' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
    assert_response :success
  end

  test 'agent with club roles should not get edit' do
    sign_in(@agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      club_role.role = role
      club_role.save
      get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
      assert_response :unauthorized
    end
  end

  test 'agent with club role should update email_template' do
    sign_agent_with_club_role(:agent, 'admin')
    comm = FactoryBot.create(:email_template, terms_of_membership_id: @tom.id)
    comm1 = FactoryBot.build(:email_template, terms_of_membership_id: @tom.id)
    put :update, id: comm.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, email_template: {
      name: comm1.name, client: comm1.client, external_attributes: comm1.external_attributes, template_type: comm1.template_type, days: comm1.days
    }
    assert_redirected_to terms_of_membership_email_templates_url(partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id)
  end

  test 'non admin agent should update email_template' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        put :update, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership_id: @tom.id, id: @tom.email_templates.first.id
        assert_response :unauthorized
      end
    end
  end
end
