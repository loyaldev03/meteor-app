require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    @fulfillment_managment_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent) 
    
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @club_with_family = FactoryGirl.create(:simple_club_with_gateway_with_family)
    @club_with_api = FactoryGirl.create(:club_with_api)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @terms_of_membership_with_family = FactoryGirl.create :terms_of_membership_with_gateway_with_family, :club_id => @club_with_family.id
    @wordpress_terms_of_membership = FactoryGirl.create :wordpress_terms_of_membership_with_gateway, :club_id => @club.id

    @preferences = {'color' => 'green','car'=> 'dodge'}
    # request.env["devise.mapping"] = Devise.mappings[:agent]
 
    @unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    @credit_card = FactoryGirl.build(:credit_card_master_card)
    @enrollment_info = FactoryGirl.build(:enrollment_info)
  end


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
                                }.merge(options), :format => :json } )
  end  

  def generate_post_message(options = {},options2 = {})
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
                              :enrollment_amount => @enrollment_info.enrollment_amount,
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
                              }.merge(options),:format => :json }.merge(options2) )
  end

  def generate_put_next_bill_date(next_bill_date)
    put( :next_bill_date, { :id => @member.id, :next_bill_date => next_bill_date } )
  end

  def generate_put_cancel(cancel_date, reason)
    put( :cancel, { :id => @member.id, :cancel_date => cancel_date, :reason => reason } )
  end

  def generate_get_by_updated(club_id, start_date, end_date)
    get( :find_all_by_updated, { :club_id => club_id, :start_date => start_date, :end_date => end_date })
  end

  def generate_get_by_created(club_id, start_date, end_date)
    get( :find_all_by_created, { :club_id => club_id, :start_date => start_date, :end_date => end_date })
  end

  def generate_post_sale(amount, description, type)
    post( :sale, { :id => @member.id, :amount => amount, :description => description, :type => type } )
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
      assert_difference('ClubCashTransaction.count')do
        assert_difference('EnrollmentInfo.count')do
          assert_difference('Transaction.count')do
            assert_difference('MemberPreference.count',@preferences.size) do 
              assert_difference('Member.count') do
                Delayed::Worker.delay_jobs = true
                assert_difference('DelayedJob.count',6)do
                  generate_post_message
                  assert_response :success
                end
                Delayed::Worker.delay_jobs = false
                Delayed::Job.all.each{ |x| x.invoke_job }
              end
            end
          end
        end
      end
    end
    saved_member = Member.find_by_email(@member.email)
    membership = Membership.last
    enrollment_info = EnrollmentInfo.last
    assert_equal(enrollment_info.membership_id, membership.id)
    assert_equal(saved_member.club_cash_amount, @terms_of_membership.initial_club_cash_amount)
    transaction = Transaction.last
    assert_equal(transaction.amount, 0.5) #Enrollment amount = 0.5
  end

 test "Admin should enroll/create member with preferences when needs approval" do
    sign_in @admin_user
    @terms_of_membership.update_attribute :needs_enrollment_approval, true
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
              Delayed::Worker.delay_jobs = true
              assert_difference('DelayedJob.count',5) do # :send_active_needs_approval_email_dj_without_delay, :marketing_tool_sync_without_delay, :marketing_tool_sync_without_delay, :desnormalize_additional_data_without_delay, :desnormalize_preferences_without_delay
                generate_post_message
                assert_response :success
              end
              Delayed::Worker.delay_jobs = false
              Delayed::Job.all.each{ |x| x.invoke_job }
            end
          end
        end
      end
    end
    saved_member = Member.find_by_email(@member.email)
    membership = Membership.last
    enrollment_info = EnrollmentInfo.last
    assert_equal(enrollment_info.membership_id, membership.id)
  end

  test "Admin should enroll/create member within club related to drupal" do
    sign_in @admin_user
    @club = @club_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
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
    assert @response.body.include? '"api_role":["91284557"]'
  end

  test "Member should not be enrolled if the email is already is used." do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count') do
      assert_difference('EnrollmentInfo.count') do
        assert_difference('Transaction.count') do
          assert_difference('MemberPreference.count',@preferences.size) do 
            assert_difference('Member.count') do
              generate_post_message
              assert_response :success
            end
          end
        end
      end
    end
    email_used = @member.email
    @member = FactoryGirl.build :member_with_api, :email => email_used
    assert_difference('Membership.count',0) do
      assert_difference('EnrollmentInfo.count',0) do
        assert_difference('Transaction.count',0) do
          assert_difference('Member.count',0) do
            generate_post_message
            assert_response :success
          end
        end
      end
    end
    assert_equal @response.body, '{"message":"Membership already exists for this email address. Contact Member Services if you would like more information at: 123 456 7891.","code":"409","errors":{"status":"Already active."}}'
  end

  test "When no param is provided on creation, it should tell us so" do
    sign_in @admin_user
    assert_difference('Membership.count',0) do
      assert_difference('EnrollmentInfo.count',0) do
        assert_difference('Transaction.count',0) do
          assert_difference('Member.count',0) do
            post( :create )
            assert_response :success
          end
        end
      end
    end
    assert @response.body.include?("There are some params missing. Please check them.")
  end

  # test "Member should not be enrolled if the email is already is used, even when mes throws error." do
  #   sign_in @admin_user
  #   @credit_card = FactoryGirl.build :credit_card
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :enrollment_info
  #   @current_club = @terms_of_membership.club
  #   @current_agent = @admin_user
  #   active_merchant_stubs
  #   assert_difference('Membership.count') do
  #     assert_difference('EnrollmentInfo.count') do
  #       assert_difference('Transaction.count') do
  #         assert_difference('MemberPreference.count',@preferences.size) do 
  #           assert_difference('Member.count') do
  #             generate_post_message
  #             assert_response :success
  #           end
  #         end
  #       end
  #     end
  #   end
  #   email_used = @member.email
  #   @member = FactoryGirl.build :member_with_api, :email => email_used
  #   active_merchant_stubs_store(@credit_card, "900", "This transaction has been approved with stub", false)
  #   assert_difference('Membership.count',0) do
  #     assert_difference('EnrollmentInfo.count',0) do
  #       assert_difference('Transaction.count',0) do
  #         assert_difference('Member.count',0) do
  #           generate_post_message
  #           assert_response :success
  #         end
  #       end
  #     end
  #   end
  #   puts @response.body
  # end

  # Reject new enrollments if billing is disable
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
    assert_equal @response.body, '{"message":"We are not accepting new enrollments at this time. Please call member services at: 123 456 7891","code":"410"}'
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

  test "Fulfillment mamager should enroll/create member" do
    sign_in @fulfillment_manager_user
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
 
  #Profile fulfillment_managment
  test "fulfillment_managment should enroll/create member" do
    sign_in @fulfillment_managment_user
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

  test "When no param is provided on update, it should tell us so" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    assert_difference('Membership.count',0) do
      assert_difference('EnrollmentInfo.count',0) do
        assert_difference('Transaction.count',0) do
          assert_difference('Member.count',0) do
            put( :update, { id: @member.id } )
            assert_response :success
          end
        end
      end
    end
    assert @response.body.include?("There are some params missing. Please check them.")
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
    assert_not_nil @member.operations.last.notes

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

  #Profile fulfillment_managment
  test "fulfillment_managment user should update member" do
    sign_in @fulfillment_managment_user
    @credit_card = FactoryGirl.build :credit_card    
    @member = create_active_member(@terms_of_membership, :member_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :enrollment_info
    generate_put_message
    assert_response :success
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

    validate_credit_card_updated_only_year(active_credit_card, token, "5589548939080095", 2)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 3)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 4)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589/5489/3908/0095", 5)
    validate_credit_card_updated_only_year(active_credit_card, token, "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}", 6)
  end

  def validate_credit_card_updated_only_month(active_credit_card, token, number, amount_months)
    @credit_card = FactoryGirl.build :credit_card_american_express, :number => number
    @credit_card.expire_month = (Time.zone.now + amount_months.months).month # January is the first month.
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
    validate_credit_card_updated_only_month(active_credit_card, token, "5589-5489-3908-0095", 2)
    validate_credit_card_updated_only_month(active_credit_card, token, "5589/5489/3908/0095", 5)
    validate_credit_card_updated_only_month(active_credit_card, token, "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}", 6)
  end

  test "Multiple same credit cards with different expiration date" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)

    @credit_card = FactoryGirl.build :credit_card_master_card
    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count') do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload
    cc_token = @member.active_credit_card.token


    @credit_card.expire_year = @credit_card.expire_year + 1
    @member.reload
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @member.reload

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

  test "Should activate old credit when it is already created, if it is not expired (with slashes)" do
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
    @member2 = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_american_express, :active => true, :member_id => @member.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :member_id => @member2.id, :blacklisted => true

    @credit_card = FactoryGirl.build :credit_card_master_card
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

  # New Member when CC is already used (Sloop) and Family memberships = true
  test "New Member when CC is already used (Drupal) and Family memberships = true" do
    sign_in @admin_user
    @terms_of_membership = @terms_of_membership_with_family

    @former_member = create_active_member(@terms_of_membership_with_family, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @former_member.id
    @former_member_credit_card = @active_credit_card.token
    
    @member = FactoryGirl.build(:member_with_api)
    @credit_card = FactoryGirl.build :credit_card_master_card
    @enrollment_info = FactoryGirl.build :enrollment_info

    active_merchant_stubs_store(@credit_card.number)
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',1) do
        generate_post_message
        assert_response :success
      end
    end
  end

  # New Member when CC is already used (Sloop), Family memberships = true and email is duplicated
  test "Enroll error when CC is already used (Drupal), Family memberships = true and email is duplicated" do
    sign_in @admin_user
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, true)

    @former_member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @former_member.id
    @former_member_credit_card_token = @active_credit_card.token

    @member = FactoryGirl.build(:member_with_api, :email => @former_member.email)
    @credit_card = FactoryGirl.build :credit_card_american_express
    @enrollment_info = FactoryGirl.build :enrollment_info

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Member.count',0) do
      assert_difference('Operation.count',0) do
        assert_difference('CreditCard.count',0) do
          generate_post_message
        end
      end
    end
  end

  test "Update a profile with CC used by another member. club with family memberships" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership_with_family, :member_with_api)
    @member2 = create_active_member(@terms_of_membership_with_family, :member_with_api)

    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    old_token = @active_credit_card.token
    @active_credit_card2 = FactoryGirl.create :credit_card_american_express, :active => true, :member_id => @member2.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    token = @credit_card.token
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count',1) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, token)
    assert_not_equal(old_token, token)
  end

  # #Update a profile with CC used by another member and Family Membership = False
  test "Error Member when CC is already used (Sloop) and Family memberships = false" do
    sign_in @admin_user
    active_merchant_stubs
    
    @current_agent = @admin_user
    @former_member = create_active_member(@terms_of_membership, :member_with_api)
    @terms_of_membership.club = @former_member.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @former_member.id
    @enrollment_info = FactoryGirl.build :enrollment_info

    @member = FactoryGirl.build(:member_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("Member.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  # #Update a profile with CC used by another member and Family Membership = False
  test "Error Member when CC is already used (Sloop) and Family memberships = false with little gateway" do
    sign_in @admin_user
    active_merchant_stubs
    @club = FactoryGirl.create(:simple_club_with_litle_gateway)
    @current_agent = @admin_user
    @former_member = create_active_member(@terms_of_membership, :member_with_api)
    @terms_of_membership.club = @former_member.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @former_member.id
    @enrollment_info = FactoryGirl.build :enrollment_info

    @member = FactoryGirl.build(:member_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("Member.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  # #Update a profile with CC used by another member and Family Membership = False
  test "Error Member when CC is already used (Sloop) and Family memberships = false with authorize_net gateway" do
    sign_in @admin_user
    active_merchant_stubs
    @club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    @current_agent = @admin_user
    @former_member = create_active_member(@terms_of_membership, :member_with_api)
    @terms_of_membership.club = @former_member.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @former_member.id
    @enrollment_info = FactoryGirl.build :enrollment_info

    @member = FactoryGirl.build(:member_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("Member.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  test "Update a profile with CC used by another member. club does not allow family memberships" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member2 = create_active_member(@terms_of_membership, :member_with_api)

    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @member.id
    token = @active_credit_card.token
    @active_credit_card2 = FactoryGirl.create :credit_card_american_express, :active => true, :member_id => @member2.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.number, nil)
    assert_equal(@member.active_credit_card.token, token)
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
  test "Update a profile with CC with slashes" do
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
    active_merchant_stubs_purchase(@credit_card.number, "34234", "decline stubbed", false) 
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
    assert_equal(transaction.amount, 0.5) #Enrollment amount = 0.5
  end

  test "Should not create member's record when there is an error on MeS get token." do
    active_merchant_stubs_store
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs_store(@credit_card.number, "117", "decline stubbed", false)
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

  test "Update club cash if club is not Drupal" do
    sign_in @admin_user
    @member = create_active_member(@wordpress_terms_of_membership, :member_with_api)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @member.club_cash_amount, @member.club_cash_expire_date
    put( :club_cash, { id: @member.id, amount: new_amount, expire_date: new_expire_date , :format => :json })
    @member.reload
    assert_response :success
    assert_equal(@member.club_cash_amount, old_amount)
    assert_equal(@member.club_cash_expire_date, old_expire_date)
  end

  test "Update club cash if club is Drupal" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @member.club_cash_amount, @member.club_cash_expire_date
    put( :club_cash, id: @member.id, amount: new_amount, expire_date: new_expire_date, :format => :json )
    @member.reload
    assert_response :success
    assert_equal(@member.club_cash_amount, old_amount)
    assert_equal(@member.club_cash_expire_date, old_expire_date)
  end

  test "Update Credit Card with expire this current month" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_american_express, :active => true, :member_id => @member.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.expire_year = (Time.zone.now.in_time_zone(@member.get_club_timezone)).year
    @credit_card.expire_month = (Time.zone.now.in_time_zone(@member.get_club_timezone)).month 

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end

    @member.reload
    assert_response :success
    assert_equal(@member.active_credit_card.token, CREDIT_CARD_TOKEN[@active_credit_card.number])
  end

  test "Update member's next_bill_date provisional status" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
      
    @member.set_as_provisional
    
    next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed)
    assert_difference('Operation.count') do
      generate_put_next_bill_date(next_bill_date)
    end
    @member.reload
    date_to_check = next_bill_date.to_datetime.change(:offset => @member.get_offset_related)
    
    assert_equal I18n.l(@member.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
  end

  test "Update member's next_bill_date active status" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    
    @member.set_as_provisional
    @member.set_as_active

    next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed).to_datetime
    assert_difference('Operation.count') do
      generate_put_next_bill_date(next_bill_date)
      puts @member.get_club_timezone
    end
    @member.reload
    date_to_check = next_bill_date.to_datetime.change(:offset => @member.get_offset_related)
    assert_equal I18n.l(@member.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
  end

  test "Update member's next_bill_date applied status" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    
    @set_as_canceled
    @member.set_as_applied   
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.unable_to_perform_due_member_status'))
  end

  test "Update member's next_bill_date lapsed status" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id

    @member.set_as_provisional
    @member.set_as_canceled!
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.unable_to_perform_due_member_status'))
  end

  test "Update member's next_bill_date when payment is not expected" do
    sign_in @admin_user
    @terms_of_membership_no_payment_expected = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :is_payment_expected => false
    @member = create_active_member(@terms_of_membership_no_payment_expected, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id

    @member.set_as_provisional
    @member.set_as_canceled!
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.not_expecting_billing'))
  end

  test "Update member's next_bill_date with wrong date format" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( "25012015" )
    end
    assert @response.body.include? "Next bill date wrong format." 
  end

  test "Update member's next_bill_date with date prior to actual date" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now - 3.days, :format => :only_date) )
    end
    assert @response.body.include? "Next bill date should be older that actual date" 
    assert @response.body.include? "Is prior to actual date" 
  end

  test "Update member's next_bill_date with blank date" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
   
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( "" )
    end
    assert @response.body.include? "Next bill date should not be blank" 
    assert @response.body.include? "is blank" 
  end

  test "Supervisor should not updates member's next_bill_date" do
    sign_in @supervisor_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Representative should not updates member's next_bill_date" do
    sign_in @representative_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Agency should not updates member's next_bill_date" do
    sign_in @agency_agent
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Fulfillment manager should not updates member's next_bill_date" do
    sign_in @fulfillment_managment_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    @member.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

   test "Api agent should update member's next_bill_date" do
     sign_in @admin_user
     next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed)
 
     @member = create_active_member(@terms_of_membership, :member_with_api)
     FactoryGirl.create :credit_card, :member_id => @member.id
 
     @member.set_as_provisional
     assert_difference('Operation.count') do
      generate_put_next_bill_date( next_bill_date )
     end
     @member.reload
     date_to_check = next_bill_date.to_datetime.change(:offset => @member.get_offset_related)
     assert_equal I18n.l(@member.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
   end

  test "get members updated between given dates" do
    sign_in @admin_user
    
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    first = Member.first
    last = Member.last

    first.update_attribute :updated_at, Time.zone.now - 10.days
    last.update_attribute :updated_at, Time.zone.now - 8.days

    generate_get_by_updated first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get members updated between given dates with start date greater to end" do
    sign_in @admin_user
    generate_get_by_updated 5, Time.zone.now-9.day, Time.zone.now-11.day
    assert @response.body.include? "Check both start and end date, please. Start date is greater than end date"
  end

  test "get members updated between given dates with blank date" do
    sign_in @admin_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    
    generate_get_by_updated 5, "",Time.zone.now-10.day
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
    generate_get_by_updated 5, Time.zone.now-10.day,""
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
  end

  test "get members updated between given dates with wrong format date" do
    sign_in @admin_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    
    generate_get_by_updated 5, "1234567", Time.zone.now-10.day
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
    generate_get_by_updated 5, Time.zone.now-10.day, "1234567"
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
  end

  test "Representative should not get members updated between given dates" do
    sign_in @representative_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Supervisor should not get members updated between given dates" do
    sign_in @supervisor_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Agency should not get members updated between given dates" do
    sign_in @agency_agent
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Fulfillment manager should not get members updated between given dates" do
    sign_in @fulfillment_managment_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Api should not get members updated between given dates" do
    sign_in @api_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    first = Member.first
    last = Member.last
    first.update_attribute :updated_at, Time.zone.now - 10.days
    last.update_attribute :updated_at, Time.zone.now - 8.days

    generate_get_by_updated first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get members created between given dates" do
    sign_in @admin_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    first = Member.first
    last = Member.last
    first.update_attribute :created_at, Time.zone.now - 10.days
    last.update_attribute :created_at, Time.zone.now - 8.days

    generate_get_by_created first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get members created between given dates with blank date" do
    sign_in @admin_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    
    generate_get_by_created 5, "",Time.zone.now-10.day
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
    generate_get_by_created 5, Time.zone.now-10.day,""
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
  end

  test "get members created between given dates with wrong format date" do
    sign_in @admin_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    
    generate_get_by_created 5, "1234567",Time.zone.now-10.day
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
    generate_get_by_created 5, Time.zone.now-10.day,"1234567"
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
  end

  test "Supervisor should not get members created between given dates" do
    sign_in @supervisor_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Representative should not get members created between given dates" do
    sign_in @representative_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Agency agent should not get members created between given dates" do
    sign_in @agency_agent
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Fulfillment manager should not get members created between given dates" do
    sign_in @fulfillment_managment_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Api agent should get members created between given dates" do
    sign_in @api_user
    3.times{ create_active_member(@terms_of_membership, :member_with_api) }
    first = Member.first
    last = Member.last
    first.update_attribute :created_at, Time.zone.now - 10.days
    last.update_attribute :created_at, Time.zone.now - 8.days

    generate_get_by_created first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end
  
  # StatzHub - Add an Api method to cancel a member
  # Cancel date using a Curl call
  test "Admin should cancel member" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:member_with_api_membership)
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)

    assert_difference("Operation.count") do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :success
    end
    @member.reload
    cancel_date_to_check = cancel_date.to_datetime
    cancel_date_to_check = cancel_date_to_check.to_datetime.change(:offset => @member.get_offset_related )

    assert @member.current_membership.cancel_date > @member.current_membership.join_date
    assert_equal I18n.l(@member.current_membership.cancel_date.utc, :format => :only_date), I18n.l(cancel_date_to_check.utc, :format => :only_date)
  end

  test "Should not cancel member when reason is blank" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:member_with_api_membership)
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "" )
      assert_response :success
    end
    assert @response.body.include?("Reason missing. Please, make sure to provide a reason for this cancelation.")
  end

  test "Should cancel member even if the cancel date is the same as today" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:member_with_api_membership)
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :member_id => @member.id

    Timecop.freeze(Time.zone.now + 1.month) do
      cancel_date = I18n.l(Time.new.getlocal(@member.get_offset_related), :format => :only_date)    

      assert_difference("Operation.count") do
        generate_put_cancel( cancel_date, "reason" )
        assert_response :success
      end
      @member.reload
      cancel_date_to_check = cancel_date.to_datetime.change(:offset => @member.get_offset_related)  
      assert @member.current_membership.cancel_date > @member.current_membership.join_date
      assert_equal I18n.l(@member.current_membership.cancel_date.in_time_zone(@member.get_club_timezone), :format => :only_date), I18n.l(cancel_date_to_check, :format => :only_date)
    end
  end

  test "Should not cancel member when cancel date is in wrong format" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:member_with_api_membership)
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "" )
      assert_response :success
    end
    assert @response.body.include?("Reason missing. Please, make sure to provide a reason for this cancelation.")
  end

  test "Supervisor should not cancel memeber" do
    sign_in @supervisor_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "Representative should not cancel memeber" do
    sign_in @representative_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "Agency should not cancel memeber" do
    sign_in @agency_agent
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "api should cancel memeber" do
    sign_in @api_user
    @membership = FactoryGirl.create(:member_with_api_membership)
    @member = create_active_member(@terms_of_membership, :member_with_api)
    @member.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :member_id => @member.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count") do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :success
    end
    @member.reload
    cancel_date_to_check = cancel_date.to_datetime
    cancel_date_to_check = cancel_date_to_check.to_datetime.change(:offset => @member.get_offset_related )

    assert_equal I18n.l(@member.current_membership.cancel_date.utc, :format => :only_date), I18n.l(cancel_date_to_check.utc, :format => :only_date)
  end

  test "Admin should enroll/create member with blank_cc as true even if not cc information provided." do
    sign_in @admin_user
    @club = @club_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @credit_card = FactoryGirl.build(:credit_card, :number => "", :expire_month => "", :expire_year => "")
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build :enrollment_info, :enrollment_amount => 0.0
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('EnrollmentInfo.count')do
        assert_difference('MemberPreference.count',@preferences.size) do 
          assert_difference('Member.count') do
            generate_post_message({}, {setter: { cc_blank: true }})
            assert_response :success
          end
        end
      end
    end
    credit_card = Member.last.active_credit_card
    assert_equal credit_card.token, "a"
    assert_equal credit_card.expire_month, Time.zone.now.month
    assert_equal credit_card.expire_year, Time.zone.now.year
  end

  test "Change TOM throught API - different TOM - active member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :active_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    @saved_member.reload
    assert_equal @saved_member.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_member.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
  end

  test "Do not allow change TOM throught API to same TOM - active member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :active_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Change TOM throught API - different TOM - provisional member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :provisional_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    @saved_member.reload
    assert_equal @saved_member.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_member.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
  end

  test "Do not allow change TOM throught API to same TOM - provisional member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :provisional_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Do not allow change TOM throught API - applied member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :applied_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the terms of membership."
  end

  test "Do not allow change TOM throught API - lapsed member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_member = create_active_member(@terms_of_membership, :applied_member, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the terms of membership."
  end

  test "One time billing throught API." do
    sign_in @admin_user
    ['admin', 'api'].each do |role|
      @admin_user.update_attribute :roles, role
      @member = create_active_member(@terms_of_membership, :member_with_api)
      FactoryGirl.create :credit_card, :member_id => @member.id
      @member.set_as_provisional
      
      Timecop.travel(@member.next_retry_bill_date) do
        assert_difference('Operation.count') do
          assert_difference('Transaction.count') do
            generate_post_sale(@member.terms_of_membership.installment_amount, "testing", "one-time")
          end
        end 
      end
      @member.reload
      assert_equal @member.operations.order("created_at DESC").first.operation_type, Settings.operation_types.no_recurrent_billing
    end
  end

  test "Donation billing throught API" do
    sign_in @admin_user
    ['admin', 'api'].each do |role|
      @admin_user.update_attribute :roles, role
      @member = create_active_member(@terms_of_membership, :member_with_api)
      FactoryGirl.create :credit_card, :member_id => @member.id
      @member.set_as_provisional
      
      Timecop.travel(@member.next_retry_bill_date) do
        assert_difference('Operation.count') do
          assert_difference('Transaction.count') do
            generate_post_sale(@member.terms_of_membership.installment_amount, "testing", "donation")
          end
        end 
      end
      @member.reload
      assert_equal @member.operations.order("created_at DESC").first.operation_type, Settings.operation_types.no_reccurent_billing_donation
    end
  end

  test "One-time or Donation billing throught API without amount, description or type" do
    sign_in @admin_user
    @member = create_active_member(@terms_of_membership, :member_with_api)
    FactoryGirl.create :credit_card, :member_id => @member.id
    @member.set_as_provisional

    Timecop.travel(@member.next_retry_bill_date) do
      generate_post_sale(nil, "testing", "donation")
      assert @response.body.include? "Amount, description and type cannot be blank."
      generate_post_sale(@member.terms_of_membership.installment_amount, nil,"donation")
      assert @response.body.include? "Amount, description and type cannot be blank."
      generate_post_sale(@member.terms_of_membership.installment_amount, "testing", nil)
      assert @response.body.include? "Amount, description and type cannot be blank."
    end
  end
 
  test "Should not allow sale transaction for agents that are not admin or api." do
    sign_in @admin_user
    ['representative', 'supervisor', 'agency', 'fulfillment_managment'].each do |role|
      @admin_user.update_attribute :roles, role
      @member = create_active_member(@terms_of_membership, :member_with_api)
      FactoryGirl.create :credit_card, :member_id => @member.id
      @member.set_as_provisional
      generate_post_sale(@member.terms_of_membership.installment_amount, "testing", "one-time")
      assert_response :unauthorized
    end
  end
end