require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @user = FactoryGirl.create :user
  end

  test "should not accept HTML request" do
    post :enroll, {}, :format => :html
    assert_response 406
  end

  test "should enroll/create member" do
    @credit_card = FactoryGirl.build :credit_card
    @terms_of_membership = FactoryGirl.create :terms_of_membership
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns({ :code => "000", :message =>"test"})
    assert_difference('Member.count') do
      post :enroll, { member: @credit_card.member.attributes, credit_card: @credit_card.attributes, 
        enrollment_amount: 34.34, terms_of_membership_id: @terms_of_membership.id, user_id: @user.id, 
        domain_url: @user.domain.url }, :format => :json
      assert_response :success
    end
  end
end
