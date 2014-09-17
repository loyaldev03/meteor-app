require 'test_helper'

class Api::OperationControllerTest < ActionController::TestCase

  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id

    @user = create_active_user(@terms_of_membership, :user_with_api)
  end

  def generate_post_create(member_id, operation_type, operation_date=nil, description=nil)
    post( :create, { member_id: member_id, operation_type: operation_type, 
                     operation_date: operation_date, description: description, :format => :json })
  end

  test "Create operation through API" do
    sign_in @admin_user
    assert_difference("Operation.count", 1)do
      generate_post_create(@user.id, "900", Time.zone.now, "Vip event registration")
      assert_response :success
      assert @response.body.include? "Operation created succesfully"
    end
  end
end