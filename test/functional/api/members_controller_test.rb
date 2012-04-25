require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  test "should enroll/create member" do
    @user = FactoryGirl.build :user
    @credit_card = FactoryGirl.build :credit_card
    @terms_of_membership = FactoryGirl.create :terms_of_membership
    ActiveMerchant::Billing.any_instance.stubs(:purchase).returns({ :code => "000", :message =>"test"})
    assert_difference('Member.count') do
      post :enroll, member: @credit_card.member, credit_card: @credit_card, 
        enrollment_amount: 34.34, tom_id: @terms_of_membership, user_id: @user.id, 
        domain_url: @terms_of_membership.domain_url
    end
  end
end
