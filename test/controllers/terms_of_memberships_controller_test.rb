require 'test_helper'

class TermsOfMembershipsControllerTest < ActionController::TestCase
  setup do
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
  end

  test 'Admin_by_club should not see subcription plan information from another club where it has not permissions' do
    @club_admin = FactoryBot.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = 'admin'
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom = FactoryBot.create :terms_of_membership_with_gateway, club_id: @other_club.id
    get :show, id: @tom, partner_prefix: @partner.prefix, club_prefix: @other_club.name
    assert_response :unauthorized
  end

  test 'Admin_by_club should see subcription plan information from its club' do
    @club_admin = FactoryBot.create(:confirmed_admin_agent)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = 'admin'
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @tom = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
    @tom.save
    get :show, id: @tom, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test 'Admin should get index' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success
    end
  end

  test 'Non Admins should not get index' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :index, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should get new' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success
    end
  end

  test 'Non Admins should not get new' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should create TOM' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      tom = FactoryBot.build :terms_of_membership_with_gateway, club_id: @club.id
      assert_difference('TermsOfMembership.count') do
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom.name, api_role: tom.api_role, installment_amount: tom.installment_amount, installment_period: tom.installment_period, trial_period_amount: tom.trial_period_amount, provisional_days: tom.provisional_days, club_id: tom.club_id, initial_club_cash_amount: tom.initial_club_cash_amount }, if_cannot_bill_user: @tom.if_cannot_bill
      end
      assert_redirected_to terms_of_memberships_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    end
  end

  test 'Non Admins should not create TOM' do
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_fulfillment_manager_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      tom = FactoryBot.build :terms_of_membership_with_gateway, club_id: @club.id
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom.name, api_role: tom.api_role, installment_amount: tom.installment_amount, installment_period: tom.installment_period, trial_period_amount: tom.trial_period_amount, provisional_days: tom.provisional_days, club_id: tom.club_id, initial_club_cash_amount: tom.initial_club_cash_amount }, if_cannot_bill_user: @tom.if_cannot_bill
      assert_response :unauthorized, "Agent #{agent} can create this page."
    end
  end

  test 'Admin should update TOM' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
      tom1 = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @club.id)
      put :update, id: tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom1.name, api_role: tom1.api_role, installment_amount: tom1.installment_amount, installment_period: tom1.installment_period, trial_period_amount: tom1.trial_period_amount, provisional_days: tom1.provisional_days, initial_club_cash_amount: tom.initial_club_cash_amount }
      assert_redirected_to terms_of_memberships_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
    end
  end

  test 'Non Admins should not update TOM' do
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_fulfillment_manager_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
      tom1 = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @club.id)
      put :update, id: tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom1.name, api_role: tom1.api_role, installment_amount: tom1.installment_amount, installment_period: tom1.installment_period, trial_period_amount: tom1.trial_period_amount, provisional_days: tom1.provisional_days, initial_club_cash_amount: tom.initial_club_cash_amount }
      assert_response :unauthorized, "Agent #{agent} can update this page."
    end
  end

  test 'Admin should show TOM' do
    %i[confirmed_admin_agent confirmed_supervisor_agent confirmed_representative_agent confirmed_fulfillment_manager_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
      get :show, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success
    end
  end

  test 'Non Admins should not show TOM' do
    %i[confirmed_api_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
        get :show, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should get edit' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
      get :edit, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :success
    end
  end

  test 'Non Admins should not get edit' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
        get :edit, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end

  test 'Admin should destroy TOM' do
    [:confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
      assert_difference('TermsOfMembership.count', -1) do
        delete :destroy, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
      end
      assert_redirected_to terms_of_memberships_path
    end
  end

  test 'Non Admins should not destroy TOM' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
        delete :destroy, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end

  ####################################################
  # #CLUBS ROLES
  ####################################################

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

  test 'agents that should show TOM with club roles' do
    %w[supervisor representative fulfillment_managment agency].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :show, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :success
      end
    end
  end

  test 'agents that should not show TOM with club roles' do
    %w[api landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :show, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
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

  test 'agents that should create TOM' do
    sign_agent_with_club_role(:agent, 'admin')
    tom = FactoryBot.build :terms_of_membership_with_gateway, club_id: @club.id
    assert_difference('TermsOfMembership.count') do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom.name, api_role: tom.api_role, installment_amount: tom.installment_amount, installment_period: tom.installment_period, trial_period_amount: tom.trial_period_amount, provisional_days: tom.provisional_days, club_id: tom.club_id, initial_club_cash_amount: tom.initial_club_cash_amount }, if_cannot_bill_user: @tom.if_cannot_bill
    end
    assert_redirected_to terms_of_memberships_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
  end

  test 'agents should not create TOM' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        tom = FactoryBot.build :terms_of_membership_with_gateway, club_id: @club.id
        post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom.name, api_role: tom.api_role, installment_amount: tom.installment_amount, installment_period: tom.installment_period, trial_period_amount: tom.trial_period_amount, provisional_days: tom.provisional_days, club_id: tom.club_id, initial_club_cash_amount: tom.initial_club_cash_amount }, if_cannot_bill_user: @tom.if_cannot_bill
        assert_response :unauthorized, "Agent #{role} can create this page."
      end
    end
  end

  test 'agents that should update TOM' do
    %w[admin].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
        tom1 = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @club.id)
        put :update, id: tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom1.name, api_role: tom1.api_role, installment_amount: tom1.installment_amount, installment_period: tom1.installment_period, trial_period_amount: tom1.trial_period_amount, provisional_days: tom1.provisional_days, initial_club_cash_amount: tom.initial_club_cash_amount }
        assert_redirected_to terms_of_memberships_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
      end
    end
  end

  test 'agents that should not update TOM' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
        tom1 = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @club.id)
        put :update, id: tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name, terms_of_membership: { name: tom1.name, api_role: tom1.api_role, installment_amount: tom1.installment_amount, installment_period: tom1.installment_period, trial_period_amount: tom1.trial_period_amount, provisional_days: tom1.provisional_days, initial_club_cash_amount: tom.initial_club_cash_amount }
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should get edit with club role' do
    sign_agent_with_club_role(:agent, 'admin')
    get :edit, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success, 'Agent admin can not access to this page.'
  end

  test 'agents that should not get edit with club role' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :edit, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized, "Agent #{role} can access to this page."
      end
    end
  end

  test 'agents that should get delete with club role' do
    sign_agent_with_club_role(:agent, 'admin')
    assert_difference('TermsOfMembership.count', -1) do
      delete :destroy, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
    end
    assert_redirected_to terms_of_memberships_path
  end

  test 'agents should not delete tom with club roles' do
    %w[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        delete :destroy, id: @tom.id, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end
  end
end
