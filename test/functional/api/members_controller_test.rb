require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway
    @preferences = {'color' => 'green','car'=> 'dodge'}
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

# test "should not accept HTML request" do
#    @current_agent = @admin_user
#    post(:create, {}, :format => :html)
#    assert_response 406
#  end

  def generate_put_message(options = {})
    put( :update, { id: @member.id, member: { :first_name => @member.first_name, 
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
                                :birth_date => @member.birth_date
                                }.merge(options), :format => :json})
  end  

  def generate_post_message(options = {})
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
                              :preferences => @preferences,
                              :credit_card => {:number => @credit_card.number,
                                               :expire_month => @credit_card.expire_month,
                                               :expire_year => @credit_card.expire_year },
                              :product_sku => @enrollment_info.product_sku,
                              :product_description => @enrollment_info.product_description,
                              :mega_channel => @enrollment_info.mega_channel,
                              :marketing_code => @enrollment_info.marketing_code,
                              :fulfillment_code => @enrollment_info.fulfillment_code,
                              :ip_address => @enrollment_info.ip_address
                              }.merge(options),:format => :json})
  end

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
    assert_difference('MemberPreference.count',@preferences.size) do 
      assert_difference('Member.count') do
        generate_post_message
        assert_response :success
      end
    end
  end

  test "Representative should not enroll/create member" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_post_message
    assert_response :unauthorized
  end

  test "Supervisor should enroll/create member" do
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
    assert_difference('Member.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "Api user should enroll/create member" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_post_message
    assert_response :success
  end

  test "Agency should not enroll/create member" do
    sign_in @agency_agent
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
      generate_post_message
      assert_response :unauthorized
    end
  end
 

  test "admin user should update member" do
    sign_in @admin_user
    @member = FactoryGirl.create :member_with_api
    assert_difference('Operation.count') do
      generate_put_message
    end
    assert_response :success
  end

  test "api_id should be updated if batch_update enabled" do
    sign_in @admin_user
    @member = FactoryGirl.create :member_with_api
    new_api_id = @member.api_id.to_i + 10

    assert_difference('Operation.count') do
      generate_put_message
      assert_response :success
      @member.reload
      assert_not_equal new_api_id, @member.api_id
    end

    assert_difference('Operation.count') do
      generate_put_message({:api_id => new_api_id, })
      assert_response :success
      @member.reload
      assert_not_equal new_api_id, @member.api_id
    end
  end


  test "representative user should update member" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.create :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "supervisor user should update member" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.create :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "api user should update member" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.create :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "agency user should not update member" do
    sign_in @agency_agent
    @credit_card = FactoryGirl.build :credit_card    
    @member = FactoryGirl.create :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :unauthorized
  end
end
