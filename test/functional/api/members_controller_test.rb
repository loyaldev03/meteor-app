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
                                :birth_date => @member.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                               :expire_month => @credit_card.expire_month,
                                               :expire_year => @credit_card.expire_year },
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

  # Store the membership id at enrollment_infos table when enrolling a new member
  # Admin should enroll/create member with preferences
  # Billing membership by Provisional amount
  test "Admin should enroll/create member with preferences" do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('EnrollmentInfo.count')do
        assert_difference('Transaction.count')do
          assert_difference('MemberPreference.count',@preferences.size) do 
            assert_difference('Member.count') do
              generate_post_message
              assert_response :success
            end
          end
        end
      end
    end
    saved_member = Member.find_by_email(@member.email)
    membership = Membership.last
    enrollment_info = EnrollmentInfo.last
    assert_equal(enrollment_info.membership_id, membership.id)

    transaction = Transaction.last
    assert_equal(transaction.amount, 34.34) #Enrollment amount = 34.34
  end

  test "If billing is disabled member cant be enrolled." do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_club.update_attribute :billing_enable, false
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count', 0)do
      assert_difference('EnrollmentInfo.count', 0)do
        assert_difference('Transaction.count', 0)do
          assert_difference('MemberPreference.count', 0) do 
            assert_difference('Member.count', 0) do
              generate_post_message
              assert_response :success
            end
          end
        end
      end
    end
  end


  test "Representative should enroll/create member" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    active_merchant_stubs_store(@credit_card.number)
    assert_difference('Member.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "Supervisor should enroll/create member" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
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
    active_merchant_stubs
    assert_difference('Member.count',0) do
      generate_post_message
      assert_response :unauthorized
    end
  end
 

  test "admin user should update member" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    
    @credit_card = FactoryGirl.create :credit_card_master_card, :active => false
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count') do
      generate_put_message
    end
    assert_response :success
  end

  test "api_id should be updated if batch_update enabled" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
   
    @credit_card = FactoryGirl.create :credit_card_master_card, :active => false
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"

    new_api_id = @member.api_id.to_i + 10

    active_merchant_stubs_store(@credit_card.number)

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
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "supervisor user should update member" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "api user should update member" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
  end

  test "agency user should not update member" do
    sign_in @agency_agent
    @credit_card = FactoryGirl.build :credit_card    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :unauthorized
  end

  # Credit card tests.
  test "Should update credit card" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count') do
        generate_put_message
      end
    end
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])    
  end

  def validate_credit_card_updated_only_year(active_credit_card, token, number, amount_years)
    @credit_card = FactoryGirl.build :credit_card_american_express, :number => number
    @credit_card.expire_month = active_credit_card.expire_month
    @credit_card.expire_year = (Date.today + amount_years.year).year
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    assert_equal(@member.active_credit_card.token, token)
    assert_equal(@member.active_credit_card.expire_month, @credit_card.expire_month)
  end


  # Multiple same credit cards with different expiration date
  test "Should update credit card only year" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    token = active_credit_card.token
    
    active_merchant_stubs_store("5589548939080095")

    validate_credit_card_updated_only_year(active_credit_card, token, "5589548939080095", 0)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 3)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 4)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589/5489/3908/0095", 5)
    validate_credit_card_updated_only_year(active_credit_card, token, "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}", 6)
  end

  def validate_credit_card_updated_only_month(active_credit_card, token, number, amount_months)
    @credit_card = FactoryGirl.build :credit_card_american_express, :number => number
    @credit_card.expire_month = Date.today.month+amount_months # January is the first month.
    @credit_card.expire_year = active_credit_card.expire_year
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    assert_equal(@member.active_credit_card.token, token)
    assert_equal(@member.active_credit_card.expire_year, @credit_card.expire_year)
  end

  # Multiple same credit cards with different expiration date
  test "Should update credit card only month" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    token = active_credit_card.token

    active_merchant_stubs_store("5589548939080095")

    validate_credit_card_updated_only_month(active_credit_card, token, "5589548939080095", 0)
    validate_credit_card_updated_only_month(active_credit_card, token, "5589-5489-3908-0095", 1)
    validate_credit_card_updated_only_month(active_credit_card, token, "5589-5489-3908-0095", 4)
    validate_credit_card_updated_only_month(active_credit_card, token, "5589-5489-3908-0095", Date.today.month)
    validate_credit_card_updated_only_month(active_credit_card, token, "5589/5489/3908/0095", 5)
    validate_credit_card_updated_only_month(active_credit_card, token, "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}", 0)
  end

  test "Multiple same credit cards with different expiration date" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"

    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    assert_equal(@member.active_credit_card.token, cc_token)
    assert_equal(@member.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should not update credit card when dates are not changed and same number. (With 'X')" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @credit_card.expire_year = active_credit_card.expire_year
    @credit_card.expire_month = active_credit_card.expire_month

    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    assert_equal(@member.active_credit_card.token, cc_token)
  end

  # Multiple same credit cards with same expiration date
  test "Should not add new credit card with same data as the one active" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id, :expire_year => (Time.zone.now+1.year).year, :expire_month => (Time.zone.now+1.month).month
    
    ["5589548939080095", "5589 5489 3908 0095", "5589-5489-3908-0095", "5589/5489/3908/0095"].each do |number|
      @credit_card = FactoryGirl.build :credit_card_american_express
      @credit_card.number = number
      @credit_card.expire_year = @member.active_credit_card.expire_year
      @credit_card.expire_month = @member.active_credit_card.expire_month

      active_merchant_stubs_store(@credit_card.number)

      assert_difference('Operation.count',1) do
        assert_difference('CreditCard.count',0) do
          generate_put_message
        end
      end
      
      assert_response :success
      @member.reload
      assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
      assert_equal(@member.active_credit_card.expire_year, @credit_card.expire_year)
      assert_equal(@member.active_credit_card.expire_month, @credit_card.expire_month)
    end
  end

  test "Should not update credit card when invalidid credit card number" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)

    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id, :expire_month => (Time.zone.now+1.month).month
    active_credit_card.update_attribute(:expire_year, (Time.zone.now+1.year).year)
    cc_token = active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "123456789"
    @credit_card.expire_year = @member.active_credit_card.expire_year
    @credit_card.expire_month = @member.active_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_equal(@member.active_credit_card.number, nil)
    assert_not_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])    
    assert_equal(@member.active_credit_card.token, cc_token)    
  end

  # Activate an inactive credit card record
  test "Should activate old credit when it is already created, if it is not expired" do
    sign_in @admin_user
    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @member.id

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_not_equal(@member.active_credit_card.token, cc_token)
    assert_equal(@member.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with dashes)" do
    sign_in @admin_user
    number = "340-5043-2363-2976" 
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @member.id, :number => number

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_not_equal(@member.active_credit_card.token, cc_token)
    assert_equal(@member.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with spaces)" do
    sign_in @admin_user
    number = "340 5043 2363 2976"   
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @member.id, :number => number

    active_merchant_stubs_store(@credit_card.number)
    
    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_not_equal(@member.active_credit_card.token, cc_token)
    assert_equal(@member.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with tabs)" do
    sign_in @admin_user
    number = "340/5043/2363/2976"
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @member.id, :number => number

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_not_equal(@member.active_credit_card.token, cc_token)
    assert_equal(@member.active_credit_card.token, @credit_card.token)
  end

  test "Should not activate old credit card when update only number, if old is expired" do
    sign_in @admin_user
    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_number = @active_credit_card.number
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @member.id
    @credit_card.expire_month = (Time.zone.now-1.month).month
    @credit_card.expire_year = (Time.zone.now-1.year).year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[cc_number])
  end

  test "Should not update active credit card with expired month" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_expire_month = @active_credit_card.expire_month

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @active_credit_card.number
    expired_month = Time.zone.now-1.month
    @credit_card.expire_month = expired_month.month
    @credit_card.expire_year = expired_month.year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
    assert_equal(@member.active_credit_card.expire_month, cc_expire_month)
  end

  test "Should not update active credit card with expired year" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    cc_expire_year = @active_credit_card.expire_year

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @active_credit_card.number
    @credit_card.expire_year = (Time.zone.now-1.year).year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
    assert_equal(@member.active_credit_card.expire_year, cc_expire_year)
  end

  test "Update a profile with CC blacklisted" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member.id, :blacklisted => true
    cc_expire_year = @active_credit_card.expire_year
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @blacklisted_credit_card.number
    @credit_card.expire_year = @blacklisted_credit_card.expire_year
    @credit_card.expire_month = @blacklisted_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@active_credit_card.number])
  end

  test "Update a profile with CC used by another member" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member.id, :blacklisted => true
    cc_expire_year = @active_credit_card.expire_year

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "5589548939080095"
    @credit_card.expire_year = @blacklisted_credit_card.expire_year
    @credit_card.expire_month = @blacklisted_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end

  # Update a member with different CC 
  # Update same CC with dashes
  test "Update a profile with CC with dashes" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member.id, :blacklisted => true
    cc_expire_year = @active_credit_card.expire_year
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "340-5043-2363-2976"
    @credit_card.expire_year = @blacklisted_credit_card.expire_year
    @credit_card.expire_month = @blacklisted_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count',1) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end

  # Update a member with different CC 
  test "Update a profile with CC with '/'" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member.id, :blacklisted => true
    cc_expire_year = @active_credit_card.expire_year
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "340/5043/2363/2976"
    @credit_card.expire_year = @blacklisted_credit_card.expire_year
    @credit_card.expire_month = @blacklisted_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count',1) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end

  # Update a member with different CC 
  # Update same CC with spaces 
  test "Update a profile with CC with white spaces" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member.id, :blacklisted => true
    cc_expire_year = @active_credit_card.expire_year
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "340 5043 2363 2976"
    @credit_card.expire_year = @blacklisted_credit_card.expire_year
    @credit_card.expire_month = @blacklisted_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count',1) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end
  
  test "Should not create member's record when there is an error on transaction." do
    active_merchant_stubs_store
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs_purchace("34234", "decline stubbed", false) 
    assert_difference('Membership.count', 0) do
      assert_difference('EnrollmentInfo.count', 0)do
        assert_difference('Transaction.count')do
          assert_difference('MemberPreference.count', 0) do 
            assert_difference('Member.count', 0) do
              generate_post_message
              assert_response :success
            end
          end
        end
      end
    end
    transaction = Transaction.last
    assert_equal(transaction.amount, 34.34) #Enrollment amount = 34.34
  end

  test "Should not create member's record when there is an error on MeS get token." do
    active_merchant_stubs_store
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs_store(@credit_card.number, "117", "decline stubbed")
    assert_difference('Membership.count', 0) do
      assert_difference('EnrollmentInfo.count', 0)do
        assert_difference('Transaction.count',0)do
          assert_difference('MemberPreference.count',0) do 
            assert_difference('Member.count',0) do
              generate_post_message
              assert_response :success
            end
          end
        end
      end
    end
  end

end
