require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
  end

  test "should not accept HTML request" do
    post(:create, {}, :format => :html)
    assert_response 406
  end

  test "should enroll/create member" do
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership
    @enrollment_info = FactoryGirl.build :enrollment_info
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns({ :code => "000", :message =>"test"})
    assert_difference('Member.count') do
      post( :create, { member: {:first_name => @member.first_name, 
                                :last_name => @member.last_name,
                                :address => @member.address,
                                :city => @member.city, 
                                :zip => @member.zip,
                                :state => @member.state,
                                :email => @member.email,
                                :country => @member.country,
                                :phone_number => @member.phone_number,
                                :enrollment_amount => 34.34,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @member.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                                 :expire_month => @credit_card.expire_month,
                                                 :expire_year => @credit_card.expire_year },
                                enrollment_info: @enrollment_info.attributes
                                }}, :format => :json)
      assert_response :success
    end
  end

end
