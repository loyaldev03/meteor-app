require 'test_helper'

class Api::ProspectsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

  def do_post
    post( :create, { prospect: {:first_name => @member.first_name, 
                                :last_name => @member.last_name,
                                :address => @member.address,
                                :gender => 'M',
                                :city => @member.city, 
                                :zip => @member.zip,
                                :state => @member.state,
                                :email => @member.email,
                                :country => @member.country,
                                :type_of_phone_number => @member.type_of_phone_number,
                                :phone_country_code => @member.phone_country_code,
                                :phone_area_code => @member.phone_area_code,
                                :phone_local_number => @member.phone_local_number,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @member.birth_date,
                                :product_description => @enrollment_info.product_description,
                                :marketing_code => @enrollment_info.marketing_code,
                                :campaign_medium => @enrollment_info.campaign_medium,
                                :campaign_description => @enrollment_info.campaign_description,
                                :campaign_medium_version => @enrollment_info.campaign_medium_version,
                                :fulfillment_code => @enrollment_info.fulfillment_code,
                                :mega_channel => @enrollment_info.mega_channel,
                                :ip_address => @enrollment_info.ip_address,
                                :referral_host => @enrollment_info.referral_host,
                                :referral_path => @enrollment_info.referral_path,
                                :user_id => @enrollment_info.user_id,
                                :landing_url => @enrollment_info.landing_url,
                                :preferences => @enrollment_info.preferences,
                                :cookie_set => @enrollment_info.cookie_set,
                                :cookie_value => @enrollment_info.cookie_value,
                                :joint => @enrollment_info.joint,
                              },:format => :json})
  end

  test "admin should create a prospect" do
  	sign_in @admin_user
  	@member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
  	assert_difference('Prospect.count') do
      do_post
      assert_response :success
    end
  end

  test "api user should create a prospect" do
  	sign_in @api_user
  	@member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
  	assert_difference('Prospect.count') do
      do_post
      assert_response :success
    end
  end

  test "supervisor should not create a prospect" do
  	sign_in @supervisor_user
  	@member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
  	assert_difference('Prospect.count',0) do
      do_post
      assert_response :unauthorized 
    end	
  end

    test "representative should not create a prospect" do
  	sign_in @representative_user
  	@member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
  	assert_difference('Prospect.count',0) do
      do_post
      assert_response :unauthorized 
    end
  end
end

