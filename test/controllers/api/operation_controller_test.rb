require 'test_helper'

class Api::OperationControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @api_user = FactoryBot.create(:confirmed_api_agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id

    @user = create_active_user(@terms_of_membership, :user_with_api)
  end

  def generate_post_create(member_id, operation_type, operation_date = nil, description = nil)
    post(:create, member_id: member_id,
                  operation_type: operation_type,
                  operation_date: operation_date,
                  description: description, format: :json)
  end

  test 'Admin and API agents are able to create operation through API' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 1) do
          generate_post_create(@user.id, '900', Time.zone.now, 'Vip event registration')
          assert_response :success
          assert @response.body.include? 'Operation created succesfully'
        end
      end
    end
  end

  test 'Non Admin nor API agents are not able to create operation through API' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_fulfillment_manager_agent confirmed_agency_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 1) do
          generate_post_create(@user.id, '900', Time.zone.now, 'Vip event registration')
          assert_response :success
          assert @response.body.include? 'Operation created succesfully'
        end
      end
    end
  end
end
