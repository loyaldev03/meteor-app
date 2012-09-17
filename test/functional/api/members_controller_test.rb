require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

# test "should not accept HTML request" do
#    @current_agent = @admin_user
#    post(:create, {}, :format => :html)
#    assert_response 406
#  end
  test "Admin should enroll/create member with preferences" do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
      Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                      :auth_code => '111', :duplicate => false, 
                                      :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
          ) 
    )
    preferences = {'color' => 'green','car'=> 'dodge'}
    assert_difference('MemberPreference.count',preferences.size) do 
      assert_difference('Member.count') do
        post( :create, { member: {:first_name => @member.first_name, 
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
                                  :enrollment_amount => 34.34,
                                  :terms_of_membership_id => @terms_of_membership.id,
                                  :birth_date => @member.birth_date,
                                  :preferences => preferences,
                                  :credit_card => {:number => @credit_card.number,
                                                   :expire_month => @credit_card.expire_month,
                                                   :expire_year => @credit_card.expire_year },
                                  enrollment_info: @enrollment_info.attributes
                                  },:format => :json})
        assert_response :success
      end
    end

  end

  test "Representative should not enroll/create member" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    post( :create, { member: {:first_name => @member.first_name, 
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
                                :enrollment_amount => 34.34,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @member.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                                 :expire_month => @credit_card.expire_month,
                                                 :expire_year => @credit_card.expire_year },
                                enrollment_info: @enrollment_info.attributes
                                },:format => :json})
    assert_response :unauthorized
  end

  test "Supervisor should not enroll/create member" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
      Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                      :auth_code => '111', :duplicate => false, 
                                      :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
          ) 
    )
    assert_difference('Member.count',0) do
      post( :create, { member: {:first_name => @member.first_name, 
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
                                :enrollment_amount => 34.34,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @member.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                                 :expire_month => @credit_card.expire_month,
                                                 :expire_year => @credit_card.expire_year },
                                enrollment_info: @enrollment_info.attributes
                                },:format => :json})
      assert_response :unauthorized
    end
  end

  test "Api user should enroll/create member" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    post( :create, { member: {:first_name => @member.first_name, 
                                :last_name => @member.last_name,
                                :address => @member.address,
                                :gender => 'M',
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

  # test "admin user should update member" do
  #   sign_in @admin_user
  #   @credit_card = FactoryGirl.build :credit_card    
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :enrollment_info
  #   put( :update, { member: {:first_name => @member.first_name, 
  #                               :last_name => @member.last_name,
  #                               :address => @member.address,
  #                               :gender => 'M',
  #                               :city => @member.city, 
  #                               :zip => @member.zip,
  #                               :state => @member.state,
  #                               :email => @member.email,
  #                               :country => @member.country,
  #                               :type_of_phone_number => @member.type_of_phone_number,
  #                               :phone_country_code => @member.phone_country_code,
  #                               :phone_area_code => @member.phone_area_code,
  #                               :phone_local_number => @member.phone_local_number,
  #                               :birth_date => @member.birth_date,
  #                               },:format => :json})
  #   assert_response :success
  # end

  # test "representative user should not update member" do
  #   sign_in @representative_user
  #   @credit_card = FactoryGirl.build :credit_card    
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :enrollment_info
  #   put( :update, { member: {:first_name => @member.first_name, 
  #                               :last_name => @member.last_name,
  #                               :address => @member.address,
  #                               :gender => 'M',
  #                               :city => @member.city, 
  #                               :zip => @member.zip,
  #                               :state => @member.state,
  #                               :email => @member.email,
  #                               :country => @member.country,
  #                               :type_of_phone_number => @member.type_of_phone_number,
  #                               :phone_country_code => @member.phone_country_code,
  #                               :phone_area_code => @member.phone_area_code,
  #                               :phone_local_number => @member.phone_local_number,
  #                               :birth_date => @member.birth_date,
  #                               },:format => :json})
  #   assert_response :unauthorized
  # end

  # test "supervisor user should not update member" do
  #   sign_in @supervisor_user
  #   @credit_card = FactoryGirl.build :credit_card    
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :enrollment_info
  #   put( :update, { member: {:first_name => @member.first_name, 
  #                               :last_name => @member.last_name,
  #                               :address => @member.address,
  #                               :gender => 'M',
  #                               :city => @member.city, 
  #                               :zip => @member.zip,
  #                               :state => @member.state,
  #                               :email => @member.email,
  #                               :country => @member.country,
  #                               :type_of_phone_number => @member.type_of_phone_number,
  #                               :phone_country_code => @member.phone_country_code,
  #                               :phone_area_code => @member.phone_area_code,
  #                               :phone_local_number => @member.phone_local_number,
  #                               :birth_date => @member.birth_date,
  #                               },:format => :json})
  #   assert_response :unauthorized
  # end

  # test "api user should update member" do
  #   sign_in @api_user
  #   @credit_card = FactoryGirl.build :credit_card    
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :enrollment_info
  #   put( :update, { member: {:first_name => @member.first_name, 
  #                               :last_name => @member.last_name,
  #                               :address => @member.address,
  #                               :gender => 'M',
  #                               :city => @member.city, 
  #                               :zip => @member.zip,
  #                               :state => @member.state,
  #                               :email => @member.email,
  #                               :country => @member.country,
  #                               :type_of_phone_number => @member.type_of_phone_number,
  #                               :phone_country_code => @member.phone_country_code,
  #                               :phone_area_code => @member.phone_area_code,
  #                               :phone_local_number => @member.phone_local_number,
  #                               :birth_date => @member.birth_date,
  #                               },:format => :json})
  #   assert_response :success
  # end
end
