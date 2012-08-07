require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    sign_in @admin_user
  end

# test "should not accept HTML request" do
#    @current_agent = @admin_user
#    post(:create, {}, :format => :html)
#    assert_response 406
#  end
  test "should enroll/create member" do
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
      Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                      :auth_code => '111', :duplicate => false, 
                                      :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
          ) 
    )
    assert_difference('Member.count') do
      post( :create, { member: {:first_name => @member.first_name, 
                                :last_name => @member.last_name,
                                :address => @member.address,
                                :city => @member.city, 
                                :zip => @member.zip,
                                :state => @member.state,
                                :email => @member.email,
                                :country => @member.country,
                                :phone_country_code => @member.phone_country_code,
                                :phone_area_code => @member.phone_area_code,
                                :phone_local_number => @member.phone_local_number,
                                :enrollment_amount => 34.34,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @member.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                                 :expire_month => @credit_card.expire_month,
                                                 :expire_year => @credit_card.expire_year },
                                enrollment_info: @enrollment_info.attributes
                                },:format => :json})
      assert_response :success
    end
  end

  test "should get stock." do
    product = FactoryGirl.create(:product, :club_id => 1)
    get(:get_stock, { :club_id => 1, :sku => 'Bracelet' ,:format => :json })
    assert_response :success
  end
end
