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
    post( :create, { prospect: {:first_name => @user.first_name, 
                                :last_name => @user.last_name,
                                :address => @user.address,
                                :gender => 'M',
                                :city => @user.city, 
                                :zip => @user.zip,
                                :state => @user.state,
                                :email => @user.email,
                                :country => @user.country,
                                :type_of_phone_number => @user.type_of_phone_number,
                                :phone_country_code => @user.phone_country_code,
                                :phone_area_code => @user.phone_area_code,
                                :phone_local_number => @user.phone_local_number,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @user.birth_date,
                                :product_description => @enrollment_info.product_description,
                                :audience => @enrollment_info.audience,
                                :utm_medium => @enrollment_info.utm_medium,
                                :campaign_description => @enrollment_info.campaign_description,
                                :utm_content => @enrollment_info.utm_content,
                                :campaign_id => @enrollment_info.campaign_code,
                                :utm_campaign => @enrollment_info.utm_campaign,
                                :ip_address => @enrollment_info.ip_address,
                                :referral_host => @enrollment_info.referral_host,
                                :referral_path => @enrollment_info.referral_path,
                                :visitor_id => @enrollment_info.visitor_id,
                                :landing_url => @enrollment_info.landing_url,
                                :preferences => @enrollment_info.preferences,
                                :cookie_set => @enrollment_info.cookie_set,
                                :cookie_value => @enrollment_info.cookie_value,
                                :utm_source => @enrollment_info.utm_source,
                                :joint => @enrollment_info.joint,
                              },:format => :json})
  end

  test "admin should create a prospect" do
    sign_in @admin_user
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    assert_difference('Operation.count') do
      assert_difference('Prospect.count') do
        do_post
        assert_response :success
      end
    end
    assert_equal(Prospect.first.club_id, @terms_of_membership.club_id)
  end

  test "api user should create a prospect" do
    sign_in @api_user
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    assert_difference('Operation.count') do
      assert_difference('Prospect.count') do
        response = do_post
        prospect = Prospect.find JSON.parse(response.body)["prospect_id"]
        assert_response :success
        assert_equal prospect.utm_source, @enrollment_info.utm_source
      end
    end
  end

  test "supervisor should not create a prospect" do
    sign_in @supervisor_user
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    assert_difference('Prospect.count',0) do
      do_post
      assert_response :unauthorized 
    end 
  end

  test "representative should not create a prospect" do
    sign_in @representative_user
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    assert_difference('Prospect.count',0) do
      do_post
      assert_response :unauthorized 
    end
  end

  test "try to create a prospect without sending params" do
    sign_in @admin_user
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    post( :create, {:format => :json})
    assert @response.body.include? "There are some params missing. Please check them."
    assert_response :success

    post( :create, {:first_name => @user.first_name, :format => :json})
    assert @response.body.include? "There are some params missing. Please check them."
    assert_response :success
  end
end

