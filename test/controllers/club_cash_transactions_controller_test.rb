require 'test_helper'

class ClubCashTransactionsControllerTest < ActionController::TestCase
  setup do
    @club                = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
    @saved_user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
  end

  test 'allows to get list of club cash transactions' do
    %i[confirmed_admin_agent confirmed_supervisor_agent confirmed_agency_agent 
       confirmed_representative_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :index, partner_prefix: @club.partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, format: :json
        assert_response :success
      end
    end
  end

  test 'does not allow to get list of club cash transactions' do
    %i[confirmed_api_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :index, partner_prefix: @club.partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, format: :json
        assert_response :unauthorized
      end
    end
  end

  test 'allows to get list of club cash transactions by club role' do
    %w[admin supervisor representative agency fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :index, partner_prefix: @club.partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, format: :json
        assert_response :success
      end
    end
  end

  test 'does allows to get list of club cash transactions by club role from other club' do
    %w[admin supervisor representative  agency fulfillment_managment].each do |role|
      @another_club        = FactoryBot.create(:simple_club_with_gateway)
      @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
      @saved_user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :index, partner_prefix: @another_club.partner.prefix, club_prefix: @another_club.name, user_prefix: @saved_user.id, format: :json
        assert_response :unauthorized
      end
    end
  end

  test 'does not allow to get list of club cash transactions by club role' do
    %w[api landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :index, partner_prefix: @club.partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, format: :json
        assert_response :unauthorized
      end
    end
  end
end
