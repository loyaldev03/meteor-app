require 'test_helper'

class UserNotesControllerTest < ActionController::TestCase
  setup do
    FactoryBot.create(:batch_agent)
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
    @saved_user           = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    @communication_type   = FactoryBot.create(:communication_type)
    @disposition_type     = FactoryBot.create(:disposition_type, club_id: @club.id)
    @user_note            = FactoryBot.build(:user_note, user_id: @saved_user.id, communication_type: @communication_type, disposition_type: @disposition_type)
  end

  def generate_get_new(user_note)
    get :new, partner_prefix: user_note.user.club.partner.prefix,
              club_prefix: user_note.user.club.name,
              user_prefix: user_note.user_id
  end

  def generate_post_user_note(user_note)
    post :create, partner_prefix: user_note.user.club.partner.prefix,
                  club_prefix: user_note.user.club.name,
                  user_prefix: user_note.user_id,
                  user_note: { description: user_note.description,
                               communication_type_id: user_note.communication_type_id,
                               disposition_type_id: user_note.disposition_type_id }
  end

  test 'allows to get new' do
    %i[confirmed_admin_agent confirmed_supervisor_agent
      confirmed_representative_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        generate_get_new(@user_note)
        assert_response :success
      end
    end
  end

  test 'does not allow to get new' do
    %i[confirmed_agency_agent confirmed_api_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        generate_get_new(@user_note)
        assert_response :unauthorized
      end
    end
  end

  test 'allows to post create an user note' do
    %i[confirmed_admin_agent confirmed_supervisor_agent
      confirmed_representative_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('UserNote.count') { generate_post_user_note(@user_note) }
        assert_response :redirect
      end
    end
  end

  test 'does not allow to post create an user note' do
    %i[confirmed_agency_agent confirmed_api_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('UserNote.count', 0) { generate_post_user_note(@user_note) }
        assert_response :unauthorized
      end
    end
  end

  test 'allows to post create an user note by club role' do
    %w[admin supervisor representative fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('UserNote.count') { generate_post_user_note(@user_note) }
        assert_response :redirect
      end
    end
  end

  test 'does not allow to post create an user note by club role' do
    %w[agency api landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('UserNote.count', 0) { generate_post_user_note(@user_note) }
        assert_response :unauthorized
      end
    end
  end

  test 'does not allow to post create an user note by club role from other club' do
    %w[agency api landing].each do |role|
      @another_club        = FactoryBot.create(:simple_club_with_gateway)
      @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
      @disposition_type    = FactoryBot.create(:disposition_type, club_id: @another_club.id)
      @saved_user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
      @user_note           = FactoryBot.build(:user_note, user_id: @saved_user.id, communication_type: @communication_type, disposition_type: @disposition_type)
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('UserNote.count', 0) { generate_post_user_note(@user_note) }
        assert_response :unauthorized
      end
    end
  end

  test 'allows to get new by club role' do
    %w[admin supervisor representative fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        generate_get_new(@user_note)
        assert_response :success
      end
    end
  end

  test 'does not allow to get new by club role' do
    %w[agency api landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        generate_get_new(@user_note)
        assert_response :unauthorized
      end
    end
  end

  test 'does not allow to get new within other club by club role' do
    %w[agency api landing].each do |role|
      @another_club        = FactoryBot.create(:simple_club_with_gateway)
      @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
      @disposition_type    = FactoryBot.create(:disposition_type, club_id: @another_club.id)
      @saved_user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        generate_get_new(@user_note)
        assert_response :unauthorized
      end
    end
  end
end
