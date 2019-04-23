require 'test_helper'

class PreferenceGroupsControllerTest < ActionController::TestCase
  def setup
    @partner          = FactoryBot.create(:partner)
    @club             = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @preference_group = FactoryBot.create(:preference_group, club_id: @club.id)
  end

  test 'agents that should get index' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test 'agents that should not get index' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test 'agents that should show preference groups' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :show, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test 'agents that should not show preference groups' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test 'agents that should get new' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test 'agents that should not get new' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test 'agents that should create preference groups' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      preference_group = FactoryBot.build(:preference_group, club_id: @club.id)

      assert_difference('PreferenceGroup.count', 1) do
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, code: preference_group.code, add_by_default: preference_group.add_by_default }
      end
      assert_redirected_to preference_group_path(assigns(:preference_group), partner_prefix: @partner.prefix, club_prefix: @club.name)
    end
  end

  test 'agents that should not create preference group' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, code: preference_group.code, add_by_default: preference_group.add_by_default }
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test 'agents that should get edit' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :edit, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success, "Agent #{agent} can not access to this page."
    end
  end

  test 'agents that should not get edit' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :edit, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{agent} can access to this page."
      end
    end
  end

  test 'agents that should update preference groups' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
      put :update, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, add_by_default: true }
      assert_redirected_to preference_group_path
    end
  end

  test 'agents that should not update preference groups' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
        put :update, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, add_by_default: true }
        assert_response :unauthorized, "Agent #{agent} can update this page."
      end
    end
  end

  #####################################################
  # CLUBS ROLES
  #####################################################

  test 'agent with club Admin role that should get index' do
    sign_agent_with_club_role(:agent, 'admin')
    get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success, 'Agent admin can not access to this page.'
  end

  test 'agent with club roles that should not get index' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should show preference groups with club roles' do
    sign_agent_with_club_role(:agent, 'admin')
    get :show, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success, 'Agent admin can not access to this page.'
  end

  test 'agents that should not show preference groups with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :show, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{role} can update this page."
      end
    end
  end

  test 'agents that should get new with club roles' do
    sign_agent_with_club_role(:agent, 'admin')
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success, 'Agent admin can not access to this page.'
  end

  test 'agents that should not get new with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should create preference groups with club roles' do
    sign_agent_with_club_role(:agent, 'admin')
    preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
    assert_difference('PreferenceGroup.count', 1) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, code: preference_group.code, add_by_default: preference_group.add_by_default }
    end
    assert_redirected_to preference_group_path(assigns(:preference_group), partner_prefix: @partner.prefix, club_prefix: @club.name)
  end

  test 'agents that should not create preference group with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, code: preference_group.code, add_by_default: preference_group.add_by_default }
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should get edit with club roles' do
    sign_agent_with_club_role(:agent, 'admin')
    get :edit, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success, 'Agent admin can not access to this page.'
  end

  test 'agents that should not get edit with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :edit, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should update preference groups with club roles' do
    sign_agent_with_club_role(:agent, 'admin')
    preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
    put :update, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, add_by_default: true }
    assert_redirected_to preference_group_path
  end

  test 'agents that should not update preference groups with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        preference_group = FactoryBot.build(:preference_group, club_id: @club.id)
        put :update, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name, preference_group: { name: preference_group.name, add_by_default: true }
        assert_response :unauthorized, "Agent #{role} can update this page."
      end
    end
  end

  test 'agent with club Admin role that should NOT get index, show, edit when it allows to another club' do
    another_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    agent = FactoryBot.create(:confirmed_admin_agent, roles: '')
    ClubRole.create(club_id: another_club.id, agent_id: agent.id, role: 'admin')
    sign_in agent
    get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
    get :show, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
    get :edit, id: @preference_group.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
    sign_out agent
  end
end
