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
    
    @club = FactoryGirl.create(:simple_club_with_gateway, :family_memberships_allowed => false)
    @club_with_family = FactoryGirl.create(:simple_club_with_gateway_with_family)
    @club_with_api = FactoryGirl.create(:club_with_api)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @terms_of_membership_with_family = FactoryGirl.create :terms_of_membership_with_gateway_with_family, :club_id => @club_with_family.id
    @wordpress_terms_of_membership = FactoryGirl.create :wordpress_terms_of_membership_with_gateway, :club_id => @club.id

    @preferences = {'color' => 'green','car'=> 'dodge'}
    # request.env["devise.mapping"] = Devise.mappings[:agent]
 
    @unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    @credit_card = FactoryGirl.build(:credit_card_master_card)
    @enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
  end


  def generate_put_message(options = {})
    put( :update, { id: @user.id, member: { :first_name => @user.first_name, 
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
                                :birth_date => @user.birth_date,
                                :credit_card => {:number => @credit_card.number,
                                               :expire_month => @credit_card.expire_month,
                                               :expire_year => @credit_card.expire_year },
                                }.merge(options), :format => :json } )
  end  

  def generate_post_message(options = {},options2 = {})
    post( :create, { member: {:first_name => @user.first_name, 
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
                              :enrollment_amount => @enrollment_info.enrollment_amount,
                              :terms_of_membership_id => @terms_of_membership.id,
                              :birth_date => @user.birth_date,
                              :preferences => @preferences,
                              :credit_card => {:number => @credit_card.number,
                                               :expire_month => @credit_card.expire_month,
                                               :expire_year => @credit_card.expire_year },
                              :product_sku => @enrollment_info.product_sku,
                              :product_description => @enrollment_info.product_description,
                              :utm_campaign => @enrollment_info.utm_campaign,
                              :audience => @enrollment_info.audience,
                              :campaign_id => @enrollment_info.campaign_code,
                              :ip_address => @enrollment_info.ip_address
                              }.merge(options),:format => :json }.merge(options2) )
  end

  def generate_put_next_bill_date(next_bill_date)
    put( :next_bill_date, { :id => @user.id, :next_bill_date => next_bill_date } )
  end

  def generate_put_cancel(cancel_date, reason)
    put( :cancel, { :id => @user.id, :cancel_date => cancel_date, :reason => reason } )
  end

  def generate_get_by_updated(club_id, start_date, end_date)
    get( :find_all_by_updated, { :club_id => club_id, :start_date => start_date, :end_date => end_date })
  end

  def generate_get_by_created(club_id, start_date, end_date)
    get( :find_all_by_created, { :club_id => club_id, :start_date => start_date, :end_date => end_date })
  end

  def generate_post_sale(amount, description, type)
    post( :sale, { :id => @user.id, :amount => amount, :description => description, :type => type } )
  end

  def generate_post_get_banner_by_email(email)
    post( :get_banner_by_email, { email: email } )
  end

  def generate_post_update_terms_of_membership(user_id, terms_of_membership_id, credit_card = {}, prorated = true)
    post(:update_terms_of_membership, { :id_or_email => user_id, 
                                        :terms_of_membership_id => terms_of_membership_id,
                                        :credit_card => credit_card,
                                        :prorated => prorated, 
                                        :format => :json} )
  end

  def get_show(user_id)
    post( :show, { id: user_id, :format => :json } )

  end

  def generate_put_club_cash(user_id, amount, expire_date = nil)
    data = { id: user_id, amount: amount, format: :json }
    data.merge!({expire_date: expire_date}) if expire_date
    put(:club_cash, data)
  end

  def prepare_upgrade_downgrade_toms(yearly = true, blank_credit_card = false)
    sign_in @admin_user
    @tom_yearly = FactoryGirl.create :terms_of_membership_with_gateway_yearly, :club_id => @club.id, 
                                     :name => "YearlyTom", installment_amount: 100, provisional_days: 90,
                                     club_cash_installment_amount: 300
    @tom_monthly = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, 
                                     :name => "MonthlyTom", installment_amount: 10
    @credit_card = FactoryGirl.build :credit_card
    @second_credit_card = FactoryGirl.build :credit_card_master_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    @terms_of_membership = yearly ? @tom_yearly : @tom_monthly
    if blank_credit_card
      @enrollment_info = FactoryGirl.build :membership_with_enrollment_info, :enrollment_amount => 0.0
      @credit_card = FactoryGirl.build(:credit_card, :number => "", :expire_month => "", :expire_year => "")
      generate_post_message({}, {setter: { cc_blank: true }})
    else
      generate_post_message
    end
    @saved_user = User.find_by(email: @user.email)
  end

  def validate_transactions_upon_tom_update(previous_membership, new_membership, amount_to_process, amount_in_favor)
    #tom_change_billing
    tom_change_billing_transaction = @saved_user.transactions.where("operation_type = ?", Settings.operation_types.tom_change_billing).last
    assert_equal tom_change_billing_transaction.amount, amount_to_process
    assert_equal tom_change_billing_transaction.terms_of_membership_id, new_membership.terms_of_membership_id
    assert_equal tom_change_billing_transaction.membership_id, new_membership.id
    #membership_balance_transfer
    transaction_balance_refund = @saved_user.transactions.where("operation_type = ? and amount < 0", Settings.operation_types.membership_balance_transfer).last
    transaction_balance_sale = @saved_user.transactions.where("operation_type = ? and amount > 0", Settings.operation_types.membership_balance_transfer).last
    if amount_in_favor and amount_in_favor > 0
      assert_equal transaction_balance_refund.amount, -amount_in_favor
      assert_equal transaction_balance_refund.terms_of_membership_id, previous_membership.terms_of_membership_id
      assert_equal transaction_balance_refund.membership_id, previous_membership.id
      assert_equal transaction_balance_sale.amount, amount_in_favor
      assert_equal transaction_balance_sale.terms_of_membership_id, new_membership.terms_of_membership_id
      assert_equal transaction_balance_sale.membership_id, new_membership.id
    else
      assert_nil transaction_balance_refund
      assert_nil transaction_balance_sale
    end
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
    assert_equal(@user.active_credit_card.token, token)
    assert_equal(@user.active_credit_card.expire_month, @credit_card.expire_month)
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
    assert_equal(@user.active_credit_card.token, token)
    assert_equal(@user.active_credit_card.expire_year, @credit_card.expire_year)
  end

  # Store the membership id at enrollment_infos table when enrolling a new user
  # Admin should enroll/create user with preferences
  # Billing membership by Provisional amount
  test "Admin should enroll/create user with preferences" do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('ClubCashTransaction.count')do
        assert_difference('Transaction.count')do
          assert_difference('UserPreference.count',@preferences.size) do 
            assert_difference('User.count') do
              Delayed::Worker.delay_jobs = true
              assert_difference('DelayedJob.count',8)do # :desnormalize_preferences_without_delay, :desnormalize_additional_data_without_delay, :asyn_solr_index_without_delay x3, :assign_club_cash_without_delay, :send_fulfillment
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
    saved_user = User.find_by(email: @user.email)
    assert_equal(saved_user.club_cash_amount, @terms_of_membership.initial_club_cash_amount)
    transaction = Transaction.last
    assert_equal(transaction.amount, 0.5) #Enrollment amount = 0.5
    fulfillment = saved_user.fulfillments.first
    assert_equal fulfillment.full_name, "#{saved_user.last_name}, #{saved_user.first_name}, (#{saved_user.state})"
    assert_equal fulfillment.full_address, "#{saved_user.address}, #{saved_user.city}, #{saved_user.zip}"
    assert_equal fulfillment.full_phone_number, "#{saved_user.phone_country_code}, #{saved_user.phone_area_code}, #{saved_user.phone_local_number}"
  end

 test "Admin should enroll/create user with preferences when needs approval" do
    sign_in @admin_user
    @terms_of_membership.update_attribute :needs_enrollment_approval, true
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('Transaction.count')do
        assert_difference('UserPreference.count',@preferences.size) do 
          assert_difference('User.count') do
            Delayed::Worker.delay_jobs = true
            assert_difference('DelayedJob.count',7) do # :send_active_needs_approval_email_dj_without_delay, :marketing_tool_sync_without_delay, :marketing_tool_sync_without_delay, :desnormalize_additional_data_without_delay, :desnormalize_preferences_without_delay
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

  test "Admin should enroll/create user within club related to drupal" do
    sign_in @admin_user
    @club = @club_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('Transaction.count')do
        assert_difference('UserPreference.count',@preferences.size) do 
          assert_difference('User.count') do
            Delayed::Worker.delay_jobs = true
            generate_post_message
            assert_response :success
            Delayed::Worker.delay_jobs = false
            Delayed::Job.all.each{ |x| x.invoke_job }
          end
        end
      end
    end
    @user_created = User.find_by(email: @user.email)
    assert @response.body.include? '"bill_date":"'+@user_created.next_retry_bill_date.strftime("%m/%d/%Y")+'"'
  end

  test "User should not be enrolled if the email is already is used." do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count') do
      assert_difference('Transaction.count') do
        assert_difference('UserPreference.count',@preferences.size) do 
          Delayed::Worker.delay_jobs = true
          assert_difference('User.count') do
            generate_post_message
            assert_response :success
          end
          Delayed::Worker.delay_jobs = false
          Delayed::Job.all.each{ |x| x.invoke_job }
        end
      end
    end
    email_used = @user.email
    @user = FactoryGirl.build :user_with_api, :email => email_used
    assert_difference('Membership.count',0) do
      assert_difference('Transaction.count',0) do
        assert_difference('User.count',0) do
          generate_post_message
          assert_response :success
        end
      end
    end
    assert_equal @response.body, '{"message":"Membership already exists for this email address. Contact Member Services if you would like more information at: 123 456 7891.","code":"409","errors":{"status":"Already active."}}'
  end

  test "When no param is provided on creation, it should tell us so" do
    sign_in @admin_user
    assert_difference('Membership.count',0) do
      assert_difference('Transaction.count',0) do
        assert_difference('User.count',0) do
          post( :create )
          assert_response :success
        end
      end
    end
    assert @response.body.include?("There are some params missing. Please check them.")
  end

  # test "Member should not be enrolled if the email is already is used, even when mes throws error." do
  #   sign_in @admin_user
  #   @credit_card = FactoryGirl.build :credit_card
  #   @member = FactoryGirl.build :member_with_api
  #   @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
  #   @current_club = @terms_of_membership.club
  #   @current_agent = @admin_user
  #   active_merchant_stubs
  #   assert_difference('Membership.count') do
  #     assert_difference('Transaction.count') do
  #       assert_difference('MemberPreference.count',@preferences.size) do 
  #         assert_difference('Member.count') do
  #           generate_post_message
  #           assert_response :success
  #         end
  #       end
  #     end
  #   end
  #   email_used = @member.email
  #   @member = FactoryGirl.build :member_with_api, :email => email_used
  #   active_merchant_stubs_store(@credit_card, "900", "This transaction has been approved with stub", false)
  #   assert_difference('Membership.count',0) do
  #     assert_difference('Transaction.count',0) do
  #       assert_difference('Member.count',0) do
  #         generate_post_message
  #         assert_response :success
  #       end
  #     end
  #   end
  #   puts @response.body
  # end

  # Reject new enrollments if billing is disable
  test "If billing is disabled user cant be enrolled." do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_club.update_attribute :billing_enable, false
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count', 0)do
      assert_difference('Transaction.count', 0)do
        assert_difference('UserPreference.count', 0) do 
          assert_difference('User.count', 0) do
            generate_post_message
            assert_response :success
          end
        end
      end
    end
    assert_equal @response.body, '{"message":"We are not accepting new enrollments at this time. Please call member services at: 123 456 7891","code":"410"}'
  end

  test "Representative should enroll/create user" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    active_merchant_stubs_store(@credit_card.number)
    assert_difference('User.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "Fulfillment mamager should enroll/create user" do
    sign_in @fulfillment_manager_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    active_merchant_stubs_store(@credit_card.number)
    assert_difference('User.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "Supervisor should enroll/create user" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('User.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "Api user should enroll/create user" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_post_message
    assert_response :success
  end

  test "Agency should not enroll/create user" do
    sign_in @agency_agent
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('User.count',0) do
      generate_post_message
      assert_response :unauthorized
    end
  end
 
  #Profile fulfillment_managment
  test "fulfillment_managment should enroll/create user" do
    sign_in @fulfillment_managment_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('User.count') do
      generate_post_message
      assert_response :success
    end
  end

  test "When no param is provided on update, it should tell us so" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    assert_difference('Membership.count',0) do
      assert_difference('Transaction.count',0) do
        assert_difference('User.count',0) do
          put( :update, { id: @user.id } )
          assert_response :success
        end
      end
    end
    assert @response.body.include?("There are some params missing. Please check them.")
  end

  test "admin user should update user" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    
    @credit_card = FactoryGirl.create :credit_card_master_card, :active => false
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count') do
      generate_put_message
    end
    assert_not_nil @user.operations.last.notes

    assert_response :success
  end

  test "api_id should be updated if batch_update enabled" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
   
    @credit_card = FactoryGirl.create :credit_card_master_card, :active => false
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"

    new_api_id = @user.api_id.to_i + 10

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count') do
      generate_put_message
      assert_response :success
      @user.reload
      assert_not_equal new_api_id, @user.api_id
    end

    assert_difference('Operation.count') do
      generate_put_message({:api_id => new_api_id, })
      assert_response :success
      @user.reload
      assert_not_equal new_api_id, @user.api_id
    end
  end

  test "representative user should update user" do
    sign_in @representative_user
    @credit_card = FactoryGirl.build :credit_card    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_put_message
    assert_response :success
  end

  test "supervisor user should update user" do
    sign_in @supervisor_user
    @credit_card = FactoryGirl.build :credit_card    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_put_message
    assert_response :success
  end

  test "api user should update user" do
    sign_in @api_user
    @credit_card = FactoryGirl.build :credit_card    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_put_message
    assert_response :success
  end

  test "agency user should not update user" do
    sign_in @agency_agent
    @credit_card = FactoryGirl.build :credit_card    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_put_message
    assert_response :unauthorized
  end

  #Profile fulfillment_managment
  test "fulfillment_managment user should update user" do
    sign_in @fulfillment_managment_user
    @credit_card = FactoryGirl.build :credit_card    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @credit_card = active_credit_card
    @credit_card.number = "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}"
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    generate_put_message
    assert_response :success
  end 

  # Credit card tests.
  test "Should update credit card" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count') do
        generate_put_message
      end
    end
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])    
  end

  # Multiple same credit cards with different expiration date
  test "Should update credit card only year" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    token = active_credit_card.token
    
    active_merchant_stubs_store("5589548939080095")

    validate_credit_card_updated_only_year(active_credit_card, token, "5589548939080095", 3)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 4)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589-5489-3908-0095", 5)
    validate_credit_card_updated_only_year(active_credit_card, token, "5589/5489/3908/0095", 6)
    validate_credit_card_updated_only_year(active_credit_card, token, "XXXX-XXXX-XXXX-#{active_credit_card.last_digits}", 7)
  end

  # Multiple same credit cards with different expiration date
  test "Should update credit card only month" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
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
    @user = create_active_user(@terms_of_membership, :user_with_api)

    @credit_card = FactoryGirl.build :credit_card_master_card
    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count') do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    cc_token = @user.active_credit_card.token


    @credit_card.expire_year = @credit_card.expire_year + 1
    @user.reload
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload

    assert_equal(@user.active_credit_card.token, cc_token)
    assert_equal(@user.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should not update credit card when dates are not changed and same number. (With 'X')" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
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
    assert_equal(@user.active_credit_card.token, cc_token)
  end

  # Multiple same credit cards with same expiration date
  test "Should not add new credit card with same data as the one active" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id, :expire_year => (Time.zone.now+1.year).year, :expire_month => (Time.zone.now+1.month).month
    
    ["5589548939080095", "5589 5489 3908 0095", "5589-5489-3908-0095", "5589/5489/3908/0095"].each do |number|
      @credit_card = FactoryGirl.build :credit_card_american_express
      @credit_card.number = number
      @credit_card.expire_year = @user.active_credit_card.expire_year
      @credit_card.expire_month = @user.active_credit_card.expire_month

      active_merchant_stubs_store(@credit_card.number)

      assert_difference('Operation.count',1) do
        assert_difference('CreditCard.count',0) do
          generate_put_message
        end
      end
      
      assert_response :success
      @user.reload
      assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
      assert_equal(@user.active_credit_card.expire_year, @credit_card.expire_year)
      assert_equal(@user.active_credit_card.expire_month, @credit_card.expire_month)
    end
  end

  test "Should not update credit card when invalidid credit card number" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)

    active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id, :expire_month => (Time.zone.now+1.month).month
    active_credit_card.update_attribute(:expire_year, (Time.zone.now+1.year).year)
    cc_token = active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "123456789"
    @credit_card.expire_year = @user.active_credit_card.expire_year
    @credit_card.expire_month = @user.active_credit_card.expire_month

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_nil @user.active_credit_card.number
    assert_not_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])    
    assert_equal(@user.active_credit_card.token, cc_token)    
  end

  # Activate an inactive credit card record
  test "Should activate old credit when it is already created, if it is not expired" do
    sign_in @admin_user
    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:user_id => @user.id

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_not_equal(@user.active_credit_card.token, cc_token)
    assert_equal(@user.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with dashes)" do
    sign_in @admin_user
    number = "340-5043-2363-2976" 
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:user_id => @user.id, :number => number

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_not_equal(@user.active_credit_card.token, cc_token)
    assert_equal(@user.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with spaces)" do
    sign_in @admin_user
    number = "340 5043 2363 2976"   
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:user_id => @user.id, :number => number

    active_merchant_stubs_store(@credit_card.number)
    
    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_not_equal(@user.active_credit_card.token, cc_token)
    assert_equal(@user.active_credit_card.token, @credit_card.token)
  end

  test "Should activate old credit when it is already created, if it is not expired (with slashes)" do
    sign_in @admin_user
    number = "340/5043/2363/2976"
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    cc_token = @active_credit_card.token
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:user_id => @user.id, :number => number

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count', 2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_not_equal(@user.active_credit_card.token, cc_token)
    assert_equal(@user.active_credit_card.token, @credit_card.token)
  end

  test "Should not activate old credit card when update only number, if old is expired" do
    sign_in @admin_user
    
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    cc_number = @active_credit_card.number
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:user_id => @user.id
    @credit_card.expire_month = (Time.zone.now-1.month).month
    @credit_card.expire_year = (Time.zone.now-1.year).year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    assert_response :success
    @user.reload
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[cc_number])
  end

  test "Should not update active credit card with expired month" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
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
    @user.reload
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
    assert_equal(@user.active_credit_card.expire_month, cc_expire_month)
  end

  test "Should not update active credit card with expired year" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
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
    @user.reload
    assert_response :success
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
    assert_equal(@user.active_credit_card.expire_year, cc_expire_year)
  end

  test "Update a profile with CC blacklisted" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user2 = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_american_express, :active => true, :user_id => @user.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :user_id => @user2.id, :blacklisted => true

    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @user.reload
    assert_response :success
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@active_credit_card.number])
  end

  # New User when CC is already used (Sloop) and Family memberships = true
  test "New User when CC is already used (Drupal) and Family memberships = true" do
    sign_in @admin_user
    @terms_of_membership = @terms_of_membership_with_family

    @former_user = create_active_user(@terms_of_membership_with_family, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @former_user.id
    @former_user_credit_card = @active_credit_card.token
    
    @user = FactoryGirl.build(:user_with_api)
    @credit_card = FactoryGirl.build :credit_card_master_card
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info

    active_merchant_stubs_store(@credit_card.number)
    assert_difference('Operation.count',4) do
      assert_difference('CreditCard.count',1) do
        generate_post_message
        assert_response :success
      end
    end
  end

  # New User when CC is already used (Sloop), Family memberships = true and email is duplicated
  test "Enroll error when CC is already used (Drupal), Family memberships = true and email is duplicated" do
    sign_in @admin_user
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, true)

    @former_user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @former_user.id
    @former_user_credit_card_token = @active_credit_card.token

    @user = FactoryGirl.build(:user_with_api, :email => @former_user.email)
    @credit_card = FactoryGirl.build :credit_card_american_express
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('User.count',0) do
      assert_difference('Operation.count',0) do
        assert_difference('CreditCard.count',0) do
          generate_post_message
        end
      end
    end
  end

  test "Update a profile with CC used by another user. club with family memberships" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership_with_family, :user_with_api)
    @user2 = create_active_user(@terms_of_membership_with_family, :user_with_api)

    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    old_token = @active_credit_card.token
    @active_credit_card2 = FactoryGirl.create :credit_card_american_express, :active => true, :user_id => @user2.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    token = @credit_card.token
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',3) do
      assert_difference('CreditCard.count',1) do
        generate_put_message
      end
    end
    @user.reload
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, token)
    assert_not_equal(old_token, token)
  end

  # #Update a profile with CC used by another user and Family Membership = False
  test "Error User when CC is already used (Sloop) and Family memberships = false" do
    sign_in @admin_user
    active_merchant_stubs
    
    @current_agent = @admin_user
    @former_user = create_active_user(@terms_of_membership, :user_with_api)
    @terms_of_membership.club = @former_user.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @former_user.id
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info

    @user = FactoryGirl.build(:user_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("User.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  # #Update a profile with CC used by another user and Family Membership = False
  test "Error User when CC is already used (Sloop) and Family memberships = false with little gateway" do
    sign_in @admin_user
    active_merchant_stubs
    @club = FactoryGirl.create(:simple_club_with_litle_gateway)
    @current_agent = @admin_user
    @former_user = create_active_user(@terms_of_membership, :user_with_api)
    @terms_of_membership.club = @former_user.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @former_user.id
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info

    @user = FactoryGirl.build(:user_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("User.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  # #Update a profile with CC used by another user and Family Membership = False
  test "Error User when CC is already used (Sloop) and Family memberships = false with authorize_net gateway" do
    sign_in @admin_user
    active_merchant_stubs
    @club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    @current_agent = @admin_user
    @former_user = create_active_user(@terms_of_membership, :user_with_api)
    @terms_of_membership.club = @former_user.club
    @terms_of_membership.club.update_attribute(:family_memberships_allowed, false)
    
    @former_active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @former_user.id
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info

    @user = FactoryGirl.build(:user_with_api, :email => "new_email@email.com")
    @credit_card = FactoryGirl.build :credit_card_master_card
    active_merchant_stubs_store(@credit_card.number)
  
    assert_equal @terms_of_membership.club.family_memberships_allowed, false
    assert_difference("User.count",0) do
      assert_difference("CreditCard.count",0) do
        generate_post_message
        assert_equal @response.body, '{"message":"We'+"'"+'re sorry but our system shows that the credit card you entered is already in use! Please try another card or call our members services at: 123 456 7891.","code":"9507","errors":{"number":"Credit card is already in use"}}'
      end
    end
  end

  test "Update a profile with CC used by another user. club does not allow family memberships" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user2 = create_active_user(@terms_of_membership, :user_with_api)

    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    token = @active_credit_card.token
    @active_credit_card2 = FactoryGirl.create :credit_card_american_express, :active => true, :user_id => @user2.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end
    @user.reload
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, token)
  end

  # Update a member with different CC 
  # Update same CC with dashes
  test "Update a profile with CC with dashes" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :user_id => @user.id, :blacklisted => true
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
    @user.reload
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end

  # Update a member with different CC 
  test "Update a profile with CC with slashes" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :user_id => @user.id, :blacklisted => true
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
    @user.reload
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end

  # Update an user with different CC 
  # Update same CC with spaces 
  test "Update a profile with CC with white spaces" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :user_id => @user.id
    @blacklisted_credit_card = FactoryGirl.create :credit_card_master_card, :active => false, :user_id => @user.id, :blacklisted => true
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
    @user.reload
    assert_response :success
    assert_nil @user.active_credit_card.number
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
  end
  
  test "Should not create user's record when there is an error on transaction." do
    active_merchant_stubs_store
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs_purchase(@credit_card.number, "34234", "decline stubbed", false) 
    assert_difference('Membership.count', 0) do
      assert_difference('Transaction.count')do
        assert_difference('UserPreference.count', 0) do 
          assert_difference('User.count', 0) do
            generate_post_message
            assert_response :success
          end
        end
      end
    end
    transaction = Transaction.last
    assert_equal(transaction.amount, 0.5) #Enrollment amount = 0.5
  end

  test "Should not create user's record when there is an error on MeS get token." do
    active_merchant_stubs_store
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs_store(@credit_card.number, "117", "decline stubbed", false)
    assert_difference('Membership.count', 0) do
      assert_difference('Transaction.count',0)do
        assert_difference('UserPreference.count',0) do 
          assert_difference('User.count',0) do
            generate_post_message
            assert_response :success
          end
        end
      end
    end
  end

  test "Update club cash if club is not Drupal" do
    sign_in @admin_user
    @user = create_active_user(@wordpress_terms_of_membership, :user_with_api)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
    put( :club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date , :format => :json })
    @user.reload
    assert_response :success

    assert_equal(@user.club_cash_amount, old_amount)
    assert @user.club_cash_expire_date == old_expire_date
  end

  test "Update club cash if club is Drupal" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
    put( :club_cash, id: @user.id, amount: new_amount, expire_date: new_expire_date, :format => :json )
    @user.reload
    assert_response :success
    assert_equal(@user.club_cash_amount, old_amount)
    assert @user.club_cash_expire_date == old_expire_date
  end

  test "Should not update club cash amount when provided a negative amount." do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    old_club_cash = @user.club_cash_amount
    generate_put_club_cash(@user.id, -1000)
    @response.body.include? I18n.t('error_messages.club_cash.negative_amount')
    assert_response :success
    @user.reload
    assert_equal old_club_cash, @user.club_cash_amount
  end

  test "Update Credit Card with expire this current month" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_american_express, :active => true, :user_id => @user.id

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.expire_year = (Time.zone.now.in_time_zone(@user.get_club_timezone)).year
    @credit_card.expire_month = (Time.zone.now.in_time_zone(@user.get_club_timezone)).month 

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_put_message
      end
    end

    @user.reload
    assert_response :success
    assert_equal(@user.active_credit_card.token, CREDIT_CARD_TOKEN[@active_credit_card.number])
  end

  test "Update user's next_bill_date provisional status" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
      
    @user.set_as_provisional
    @user.update_attribute :recycled_times, 1

    next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed)
    assert_difference('Operation.count') do
      generate_put_next_bill_date(next_bill_date)
    end
    @user.reload
    date_to_check = next_bill_date.to_datetime.change(:offset => @user.get_offset_related)
    assert_equal I18n.l(@user.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
    assert_equal @user.recycled_times, 0
  end

  test "Update user's next_bill_date active status" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    
    @user.set_as_provisional
    @user.set_as_active
    @user.update_attribute :recycled_times, 1

    next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed).to_datetime
    assert_difference('Operation.count') do
      generate_put_next_bill_date(next_bill_date)
    end
    @user.reload
    date_to_check = next_bill_date.to_datetime.change(:offset => @user.get_offset_related)
    assert_equal I18n.l(@user.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
    assert_equal @user.recycled_times, 0
  end

  test "Update user's next_bill_date applied status" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    
    @set_as_canceled
    @user.set_as_applied   
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.unable_to_perform_due_user_status'))
  end

  test "Update user's next_bill_date lapsed status" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id

    @user.set_as_provisional
    @user.set_as_canceled!
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.unable_to_perform_due_user_status'))
  end

  test "Update user's next_bill_date when payment is not expected" do
    sign_in @admin_user
    @terms_of_membership_no_payment_expected = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :is_payment_expected => false
    @user = create_active_user(@terms_of_membership_no_payment_expected, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id

    @user.set_as_provisional
    @user.set_as_canceled!
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
    end
    assert @response.body.include?(I18n.t('error_messages.not_expecting_billing'))
  end

  test "Update user's next_bill_date with wrong date format" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( "25012015" )
    end
    assert @response.body.include? "Next bill date wrong format." 
  end

  test "Update user's next_bill_date with date prior to actual date" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now - 3.days, :format => :only_date) )
    end
    assert @response.body.include? "Next bill date should be older that actual date" 
    assert @response.body.include? "Is prior to actual date" 
  end

  test "Update user's next_bill_date with blank date" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
   
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( "" )
    end
    assert @response.body.include? "Next bill date should not be blank" 
    assert @response.body.include? "is blank" 
  end

  test "Supervisor should not updates user's next_bill_date" do
    sign_in @supervisor_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Representative should not updates user's next_bill_date" do
    sign_in @representative_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Agency should not updates user's next_bill_date" do
    sign_in @agency_agent
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

  test "Fulfillment manager should not updates user's next_bill_date" do
    sign_in @fulfillment_managment_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    @user.set_as_provisional
    assert_difference('Operation.count',0) do
      generate_put_next_bill_date( I18n.l(Time.zone.now + 3.days, :format => :only_date) )
      assert_response :unauthorized
    end
  end

   test "Api agent should update user's next_bill_date" do
     sign_in @admin_user
     next_bill_date = I18n.l(Time.zone.now+3.day, :format => :dashed)
 
     @user = create_active_user(@terms_of_membership, :user_with_api)
     FactoryGirl.create :credit_card, :user_id => @user.id
 
     @user.set_as_provisional
     assert_difference('Operation.count') do
      generate_put_next_bill_date( next_bill_date )
     end
     @user.reload
     date_to_check = next_bill_date.to_datetime.change(:offset => @user.get_offset_related)
     assert_equal I18n.l(@user.next_retry_bill_date.utc, :format => :only_date), I18n.l(date_to_check.utc, :format => :only_date)
   end

  test "get users updated between given dates" do
    sign_in @admin_user
    
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    first = User.first
    last = User.last

    first.update_attribute :updated_at, Time.zone.now - 10.days
    last.update_attribute :updated_at, Time.zone.now - 8.days

    generate_get_by_updated first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get users updated between given dates with start date greater to end" do
    sign_in @admin_user
    generate_get_by_updated 5, Time.zone.now-9.day, Time.zone.now-11.day
    assert @response.body.include? "Check both start and end date, please. Start date is greater than end date"
  end

  test "get users updated between given dates with blank date" do
    sign_in @admin_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    
    generate_get_by_updated 5, "",Time.zone.now-10.day
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
    generate_get_by_updated 5, Time.zone.now-10.day,""
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
  end

  test "get users updated between given dates with wrong format date" do
    sign_in @admin_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    
    generate_get_by_updated 5, "1234567", Time.zone.now-10.day
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
    generate_get_by_updated 5, Time.zone.now-10.day, "1234567"
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
  end

  test "Representative should not get users updated between given dates" do
    sign_in @representative_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Supervisor should not get users updated between given dates" do
    sign_in @supervisor_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Agency should not get users updated between given dates" do
    sign_in @agency_agent
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Fulfillment manager should not get users updated between given dates" do
    sign_in @fulfillment_managment_user
    generate_get_by_updated 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Api should not get users updated between given dates" do
    sign_in @api_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    first = User.first
    last = User.last
    first.update_attribute :updated_at, Time.zone.now - 10.days
    last.update_attribute :updated_at, Time.zone.now - 8.days

    generate_get_by_updated first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get users created between given dates" do
    sign_in @admin_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    first = User.first
    last = User.last
    first.update_attribute :created_at, Time.zone.now - 10.days
    last.update_attribute :created_at, Time.zone.now - 8.days

    generate_get_by_created first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  test "get users created between given dates with blank date" do
    sign_in @admin_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    
    generate_get_by_created 5, "",Time.zone.now-10.day
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
    generate_get_by_created 5, Time.zone.now-10.day,""
    assert @response.body.include? "Make sure to send both start and end dates, please. There seems to be at least one as null or blank"
  end

  test "get users created between given dates with wrong format date" do
    sign_in @admin_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    
    generate_get_by_created 5, "1234567",Time.zone.now-10.day
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
    generate_get_by_created 5, Time.zone.now-10.day,"1234567"
    assert @response.body.include? "Check both start and end date format, please. It seams one of them is in an invalid format"
  end

  test "Supervisor should not get users created between given dates" do
    sign_in @supervisor_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Representative should not get users created between given dates" do
    sign_in @representative_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Agency agent should not get users created between given dates" do
    sign_in @agency_agent
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Fulfillment manager should not get users created between given dates" do
    sign_in @fulfillment_managment_user
    generate_get_by_created 5, Time.zone.now-11.day, Time.zone.now-9.day
    assert_response :unauthorized
  end

  test "Api agent should get users created between given dates" do
    sign_in @api_user
    3.times{ create_active_user(@terms_of_membership, :user_with_api) }
    first = User.first
    last = User.last
    first.update_attribute :created_at, Time.zone.now - 10.days
    last.update_attribute :created_at, Time.zone.now - 8.days

    generate_get_by_created first.club_id, Time.zone.now-11.day, Time.zone.now-9.day
    
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end
  
  # StatzHub - Add an Api method to cancel an user
  # Cancel date using a Curl call
  test "Admin should cancel user" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:user_with_api_membership)
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)

    assert_difference("Operation.count") do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :success
    end
    @user.reload
    cancel_date_to_check = cancel_date.to_datetime
    cancel_date_to_check = cancel_date_to_check.to_datetime.change(:offset => @user.get_offset_related )

    assert @user.current_membership.cancel_date > @user.current_membership.join_date
    assert_equal I18n.l(@user.current_membership.cancel_date.utc, :format => :only_date), I18n.l(cancel_date_to_check.utc, :format => :only_date)
  end

  test "Should not cancel user when reason is blank" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:user_with_api_membership)
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "" )
      assert_response :success
    end
    assert @response.body.include?("Reason missing. Please, make sure to provide a reason for this cancelation.")
  end

  test "Should cancel user even if the cancel date is the same as today" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:user_with_api_membership)
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :user_id => @user.id

    Timecop.freeze(Time.zone.now + 1.month) do
      cancel_date = I18n.l(Time.new.getlocal(@user.get_offset_related), :format => :only_date)    

      assert_difference("Operation.count") do
        generate_put_cancel( cancel_date, "reason" )
        assert_response :success
      end
      @user.reload
      cancel_date_to_check = cancel_date.to_datetime.change(:offset => @user.get_offset_related)  
      assert @user.current_membership.cancel_date > @user.current_membership.join_date
      assert_equal I18n.l(@user.current_membership.cancel_date.in_time_zone(@user.get_club_timezone), :format => :only_date), I18n.l(cancel_date_to_check, :format => :only_date)
    end
  end

  test "Should not cancel user when cancel date is in wrong format" do
    sign_in @admin_user
    @membership = FactoryGirl.create(:user_with_api_membership)
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "" )
      assert_response :success
    end
    assert @response.body.include?("Reason missing. Please, make sure to provide a reason for this cancelation.")
  end

  test "Supervisor should not cancel memeber" do
    sign_in @supervisor_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "Representative should not cancel memeber" do
    sign_in @representative_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "Agency should not cancel memeber" do
    sign_in @agency_agent
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count",0) do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :unauthorized
    end
  end

  test "api should cancel memeber" do
    sign_in @api_user
    @membership = FactoryGirl.create(:user_with_api_membership)
    @user = create_active_user(@terms_of_membership, :user_with_api)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryGirl.create :credit_card, :user_id => @user.id
    cancel_date = I18n.l(Time.zone.now+2.days, :format => :only_date)    
    
    assert_difference("Operation.count") do
      generate_put_cancel( cancel_date, "Reason" )
      assert_response :success
    end
    @user.reload
    cancel_date_to_check = cancel_date.to_datetime
    cancel_date_to_check = cancel_date_to_check.to_datetime.change(:offset => @user.get_offset_related )

    assert_equal I18n.l(@user.current_membership.cancel_date.utc, :format => :only_date), I18n.l(cancel_date_to_check.utc, :format => :only_date)
  end

  test "Admin should enroll/create user with blank_cc as true even if not cc information provided." do
    sign_in @admin_user
    @club = @club_with_api
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @credit_card = FactoryGirl.build(:credit_card, :number => "", :expire_month => "", :expire_year => "")
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info, :enrollment_amount => 0.0
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count')do
      assert_difference('UserPreference.count',@preferences.size) do 
        assert_difference('User.count') do
          generate_post_message({}, {setter: { cc_blank: true }})
          assert_response :success
        end
      end
    end
    credit_card = User.last.active_credit_card
    assert_equal credit_card.token, "a"
    assert_equal credit_card.expire_month, Time.zone.now.month
    assert_equal credit_card.expire_year, Time.zone.now.year
  end

  test "Change TOM throught API - different TOM - active user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :active_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    @saved_user.reload
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
  end

  test "Do not allow change TOM throught API to same TOM - active user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :active_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Change TOM throught API - different TOM - provisional user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :provisional_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    @saved_user.reload
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
  end

  test "Do not allow change TOM throught API to same TOM - provisional user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :provisional_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @saved_user.terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Do not allow change TOM throught API - applied user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :applied_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the subscription plan."
  end

  test "Do not allow change TOM throught API - lapsed user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :applied_user, nil, {}, { :created_by => @admin_user })
    post(:change_terms_of_membership, { :id => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the subscription plan."
  end

  test "User should not be updated if it is already active and the cc send it is wrong" do
    sign_in @admin_user
    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    assert_difference('Membership.count') do
      assert_difference('Transaction.count') do
        assert_difference('UserPreference.count',@preferences.size) do 
          Delayed::Worker.delay_jobs = true
          assert_difference('User.count') do
            generate_post_message
            assert_response :success
          end
          Delayed::Worker.delay_jobs = false
          Delayed::Job.all.each{ |x| x.invoke_job }
        end
      end
    end
    email_used = @user.email
    @user.first_name = "new_Name"
    @credit_card.expire_month = (Time.zone.now - 1.day).year
    @user = FactoryGirl.build :user_with_api, :email => email_used
    assert_difference('Membership.count',0) do
      assert_difference('Transaction.count',0) do
        assert_difference('User.count',0) do
          generate_post_message
          assert_response :success
        end
      end
    end
    assert @response.body.include? "Member information is invalid."
    assert @response.body.include? "\"expire_year\":[\"expired\"]"
    saved_user = User.find_by(email: @user.email)
    assert saved_user.first_name != "new_Name"
  end

  test "Update TOM throught API - sending Email" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user_2 = create_active_user(@terms_of_membership_with_family, :active_user, nil, {}, { :created_by => @admin_user })
    @saved_user = create_active_user(@terms_of_membership, :active_user, nil, {}, { :created_by => @admin_user })
    @saved_user_2.update_attribute :email, @saved_user.email
    post(:update_terms_of_membership, { :id_or_email => @saved_user.email, :terms_of_membership_id => @terms_of_membership_second.id, :prorated => 0, :format => :json} )
    @saved_user.reload
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.update_terms_of_membership
  end

  test "Update TOM throught API - different TOM - active user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :active_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :prorated => 0 ,:format => :json} )
    @saved_user.reload
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.update_terms_of_membership
  end

  test "Do not allow update TOM throught API to same TOM - active user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :active_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @terms_of_membership.id, :prorated => 0, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Update TOM throught API - different TOM - provisional user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :provisional_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :prorated => 0, :format => :json} )
    @saved_user.reload
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.update_terms_of_membership
  end

  test "Do not allow update TOM throught API to same TOM - provisional user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :provisional_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @saved_user.terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
  end

  test "Do not allow update TOM throught API - applied member" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :applied_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the subscription plan."
  end

  test "Do not allow update TOM throught API - lapsed user" do
    sign_in @admin_user
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    @saved_user = create_active_user(@terms_of_membership, :applied_user, nil, {}, { :created_by => @admin_user })
    post(:update_terms_of_membership, { :id_or_email => @saved_user.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the subscription plan."
  end

  test "Do not upgrade if we enter a wrong CC - Provisional Status" do
    prepare_upgrade_downgrade_toms 
    credit_card_params = {:number => "4111111111111112", :expire_month => "2", :expire_year => "2014" }
    generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id, credit_card_params)
    assert @response.body.include? I18n.t('error_messages.invalid_credit_card')
  end

  test "Do not upgrade if we enter a wrong CC - Active Status" do
    prepare_upgrade_downgrade_toms 

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      credit_card_params = {:number => "4111111111111112", :expire_month => "2", :expire_year => "2014" }
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id, credit_card_params)
    end
    assert @response.body.include? I18n.t('error_messages.invalid_credit_card')
  end

  test "Upgrade a User if it add a new valid CC -when the user has CC blank - Set active = True" do
    prepare_upgrade_downgrade_toms false, true
    previous_membership = @saved_user.current_membership

    generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id, {:set_active => 1, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_yearly.id
    assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
  end

  test "Downgrade a User if it add a new valid CC-when the user has CC blank - Set active = True" do
    prepare_upgrade_downgrade_toms true, true
    previous_membership = @saved_user.current_membership
    
    generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id, {:set_active => 1, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_monthly.id
    assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
  end

  test "Upgrade a User if it add a new valid CC - Set active = False" do
    prepare_upgrade_downgrade_toms false
    previous_membership = @saved_user.current_membership
    amount_in_favor = 0
    amount_to_process = 0
    prorated_club_cash = 0

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      days_until_nbd = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor = ((@tom_monthly.installment_amount.to_f*(days_until_nbd/@tom_monthly.installment_period.to_f)) * 100).round / 100.0
      amount_to_process = ((@tom_yearly.installment_amount - amount_in_favor)*100).round / 100.0
      prorated_club_cash = (@tom_monthly.club_cash_installment_amount*(days_until_nbd/@tom_monthly.installment_period.to_f)).round
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id, {:set_active => 0, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    end

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_yearly.id
    assert_equal @saved_user.active_credit_card.last_digits, @credit_card.number.last(4)
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor)
  end

  test "Downgrade a User if it add a new valid CC - Set active = False" do
    prepare_upgrade_downgrade_toms
    previous_membership = @saved_user.current_membership
    amount_in_favor = 0
    amount_to_process = 0
    prorated_club_cash = 0

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      days_until_nbd = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor = ((@tom_yearly.installment_amount.to_f*(days_until_nbd/@tom_yearly.installment_period.to_f)) * 100).round / 100.0
      amount_to_process = ((@tom_monthly.installment_amount - amount_in_favor)*100).round / 100.0
      prorated_club_cash = (@tom_yearly.club_cash_installment_amount*(days_until_nbd/@tom_yearly.installment_period.to_f)).round
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id, {:set_active => 0, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    end

    @saved_user.reload
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor)
  end

  # Upgrade User with Basic membership level by prorate logic - Active User
  test "Upgrade a User if it add a update valid CC (prorated logic) - Active User " do 
    Delayed::Worker.delay_jobs = true
    prepare_upgrade_downgrade_toms false
    previous_membership = @saved_user.current_membership
    amount_in_favor = 0
    amount_to_process = 0
    prorated_club_cash = 0

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Job.all.each{ |x| x.destroy }
    
    @saved_user.reload
    previous_club_cash_amount = @saved_user.club_cash_amount
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      days_until_nbd = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor = ((@tom_monthly.installment_amount.to_f*(days_until_nbd/@tom_monthly.installment_period.to_f)) * 100).round / 100.0
      amount_to_process = ((@tom_yearly.installment_amount - amount_in_favor)*100).round / 100.0
      prorated_club_cash = (@tom_monthly.club_cash_installment_amount*(days_until_nbd/@tom_monthly.installment_period.to_f)).round
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id, {:set_active => 1, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Worker.delay_jobs = false

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_yearly.id
    assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor)
    assert_not_nil @saved_user.operations.where("description like ?", "%Prorating club cash. Adding #{@tom_yearly.club_cash_installment_amount} minus #{prorated_club_cash} from previous Subscription plan.%")
    assert_equal @saved_user.club_cash_amount, previous_club_cash_amount + @tom_yearly.club_cash_installment_amount - prorated_club_cash
  end

  # Downgrade User with PREMIUM membership level by prorate logic - Active User
  test "Downgrade a User if it add a update valid CC (prorated logic) - Active User" do
    Delayed::Worker.delay_jobs = true
    prepare_upgrade_downgrade_toms
    previous_membership = @saved_user.current_membership
    amount_in_favor = 0
    amount_to_process = 0
    prorated_club_cash = 0

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Job.all.each{ |x| x.destroy }
    
    @saved_user.reload
    previous_club_cash_amount = @saved_user.club_cash_amount
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      days_until_nbd = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor = ((@tom_yearly.installment_amount.to_f*(days_until_nbd/@tom_yearly.installment_period.to_f)) * 100).round / 100.0
      amount_to_process = ((@tom_monthly.installment_amount - amount_in_favor)*100).round / 100.0
      prorated_club_cash = (@tom_yearly.club_cash_installment_amount*(days_until_nbd/@tom_yearly.installment_period.to_f)).round
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id, {:set_active => 1, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Worker.delay_jobs = false

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_monthly.id
    assert_equal @saved_user.active_credit_card.last_digits, @second_credit_card.number.last(4)
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, amount_to_process, amount_in_favor)
    assert_not_nil @saved_user.operations.where("description like ?", "%Prorating club cash. Adding #{@tom_yearly.club_cash_installment_amount} minus #{prorated_club_cash} from previous Subscription plan.%")
    assert_equal @saved_user.club_cash_amount, previous_club_cash_amount + @tom_monthly.club_cash_installment_amount - prorated_club_cash
  end

  test "Upgrade/Downgrade should leave 0 club cash when we have to remove more club cash amount than available" do
    Delayed::Worker.delay_jobs = true
    prepare_upgrade_downgrade_toms
    previous_membership = @saved_user.current_membership
    amount_in_favor = 0
    amount_to_process = 0
    prorated_club_cash = 0

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Job.all.each{ |x| x.destroy }

    @saved_user.reload
    @saved_user.club_cash_amount = 0
    @saved_user.save

    previous_club_cash_amount = @saved_user.club_cash_amount
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      days_until_nbd = (@saved_user.next_retry_bill_date.to_date - Time.zone.now.to_date).to_f
      amount_in_favor = ((@tom_monthly.installment_amount.to_f*(days_until_nbd/@tom_monthly.installment_period.to_f)) * 100).round / 100.0
      amount_to_process = ((@tom_yearly.installment_amount - amount_in_favor)*100).round / 100.0
      prorated_club_cash = (@tom_monthly.club_cash_installment_amount*(days_until_nbd/@tom_monthly.installment_period.to_f)).round
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id)
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Worker.delay_jobs = false

    @saved_user.reload
    assert_equal @saved_user.terms_of_membership.id, @tom_monthly.id
    assert_equal @saved_user.club_cash_amount, 0
  end

  test "Do not upgrade/downgrade if  the user has a refund already done" do
    prepare_upgrade_downgrade_toms false
    previous_membership = @saved_user.current_membership

    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end

    membership_transaction = @saved_user.transactions.where("operation_type = ?", Settings.operation_types.membership_billing).last
    Transaction.refund(membership_transaction.amount/2, membership_transaction.id)
    
    Timecop.travel(first_nbd + (@saved_user.terms_of_membership.installment_period/2).days) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id)
    end
    assert @response.body.include? I18n.t('error_messages.prorated_enroll_failure', :cs_phone_number => @saved_user.club.cs_phone_number)
  end

  test "Do not upgrade/downgrade if the user is at Lapsed or applied status" do
    prepare_upgrade_downgrade_toms false

    @saved_user.set_as_canceled
    generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id, {:set_active => 0, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    assert @response.body.include? "Member status does not allows us to change the subscription plan"
    @saved_user.set_as_applied
    generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id, {:set_active => 0, :number => @second_credit_card.number, :expire_month => @second_credit_card.expire_month, :expire_year => @second_credit_card.expire_year })
    assert @response.body.include? "Member status does not allows us to change the subscription plan"
  end

  test "Upgrade/Downgrade a User Basic membership level by prorate logic - Provisional User - NewProvisionalDays < OldProvisionalDays" do
    prepare_upgrade_downgrade_toms
    days_in_provisional = @saved_user.terms_of_membership.provisional_days/2
    middle_of_provisional_days = Time.zone.now + days_in_provisional.days
    nbd = middle_of_provisional_days + @tom_monthly.provisional_days.days
    Timecop.travel(middle_of_provisional_days) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id)
    end

    @saved_user.reload
    assert @saved_user.active?

    assert_not_nil @saved_user.operations.where("description like ?", "%Membership reached end of provisional period after Subscription Plan change to TOM(#{@tom_monthly.id}) -#{@tom_monthly.name}-. Billing $#{@tom_monthly.installment_amount}%").last
    assert_equal @saved_user.next_retry_bill_date.to_date, (middle_of_provisional_days + @tom_monthly.installment_period.days).to_date
  end

  test "Upgrade/Downgrade User with Basic membership level by prorate logic (OldProvisionalDays > NewProvisionalDays)- Softdecline User (Provisional status)" do
    prepare_upgrade_downgrade_toms
    previous_membership = @saved_user.current_membership
    sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    active_merchant_stubs(sd_strategy.response_code, "decline stubbed", false)
    
    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    active_merchant_stubs

    Timecop.travel(@saved_user.bill_date + rand(1..6).days) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_monthly.id)
    end
    @saved_user.reload
    @saved_user.active?
    assert_equal @saved_user.terms_of_membership.id, @tom_monthly.id
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, @tom_monthly.installment_amount, 0.0)
  end

  test "Upgrade/Downgrade User with Basic membership level by prorate logic - Softdecline User (Active status)" do
    prepare_upgrade_downgrade_toms false
    previous_membership = @saved_user.current_membership
    sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    
    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end

    active_merchant_stubs(sd_strategy.response_code, "decline stubbed", false)
    Timecop.travel(@saved_user.next_retry_bill_date) do
      @saved_user.bill_membership
    end
    active_merchant_stubs

    rand_date = @saved_user.bill_date + rand(1..6).days
    days_in_provisional = (rand_date.to_date - @saved_user.join_date.to_date).to_i
    nbd = rand_date + @tom_yearly.provisional_days.days
    Timecop.travel(rand_date) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id)
    end
    @saved_user.reload
    assert @saved_user.active?
    assert_equal @saved_user.terms_of_membership.id, @tom_yearly.id
    validate_transactions_upon_tom_update(previous_membership, @saved_user.current_membership, @tom_yearly.installment_amount, 0.0)
  end

  test "One time billing throught API." do
    sign_in @admin_user
    ['admin', 'api'].each do |role|
      @admin_user.update_attribute :roles, role
      @user = create_active_user(@terms_of_membership, :user_with_api)
      FactoryGirl.create :credit_card, :user_id => @user.id
      @user.set_as_provisional
      
      Timecop.travel(@user.next_retry_bill_date) do
        assert_difference('Operation.count') do
          assert_difference('Transaction.count') do
            generate_post_sale(@user.terms_of_membership.installment_amount, "testing", "one-time")
          end
        end 
      end
      @user.reload
      assert_equal @user.operations.order("created_at DESC").first.operation_type, Settings.operation_types.no_recurrent_billing
    end
  end

  test "Donation billing throught API" do
    sign_in @admin_user
    ['admin', 'api'].each do |role|
      @admin_user.update_attribute :roles, role
      @user = create_active_user(@terms_of_membership, :user_with_api)
      FactoryGirl.create :credit_card, :user_id => @user.id
      @user.set_as_provisional
      
      Timecop.travel(@user.next_retry_bill_date) do
        assert_difference('Operation.count') do
          assert_difference('Transaction.count') do
            generate_post_sale(@user.terms_of_membership.installment_amount, "testing", "donation")
          end
        end 
      end
      @user.reload
      assert_equal @user.operations.order("created_at DESC").first.operation_type, Settings.operation_types.no_reccurent_billing_donation
    end
  end

  test "One-time or Donation billing throught API without amount, description or type" do
    sign_in @admin_user
    @user = create_active_user(@terms_of_membership, :user_with_api)
    FactoryGirl.create :credit_card, :user_id => @user.id
    @user.set_as_provisional

    Timecop.travel(@user.next_retry_bill_date) do
      generate_post_sale(nil, "testing", "donation")
      assert @response.body.include? "Amount, description and type cannot be blank."
      generate_post_sale(@user.terms_of_membership.installment_amount, nil,"donation")
      assert @response.body.include? "Amount, description and type cannot be blank."
      generate_post_sale(@user.terms_of_membership.installment_amount, "testing", nil)
      assert @response.body.include? "Amount, description and type cannot be blank."
    end
  end
 
  test "Should not allow sale transaction for agents that are not admin or api." do
    sign_in @admin_user
    ['representative', 'supervisor', 'agency', 'fulfillment_managment'].each do |role|
      @admin_user.update_attribute :roles, role
      @user = create_active_user(@terms_of_membership, :user_with_api)
      FactoryGirl.create :credit_card, :user_id => @user.id
      @user.set_as_provisional
      generate_post_sale(@user.terms_of_membership.installment_amount, "testing", "one-time")
      assert_response :unauthorized
    end
  end

  test "Api should be allowed to get banner by email" do
    sign_in @admin_user
    ['api', 'admin'].each do |role|
      @admin_user.update_attribute :roles, nil
      @admin_user.add_role_with_club(role, @club)
      @user = create_active_user(@terms_of_membership, :user_with_api)
      @club.member_banner_url = "https://member_banner_url.com"
      @club.non_member_banner_url = "https://non_member.banner_url.com"
      @club.member_landing_url = "https://member_landing_url.com"
      @club.non_member_landing_url = "https://non_member_landing_url.com"
      @club.save(validate: false)
      generate_post_get_banner_by_email("")
      assert @response.body.include? @club.non_member_banner_url
      assert @response.body.include? @club.non_member_landing_url
      generate_post_get_banner_by_email("wrongFormat") 
      assert @response.body.include? @club.non_member_banner_url
      assert @response.body.include? @club.non_member_landing_url
      generate_post_get_banner_by_email("does@notexist.com") 
      assert @response.body.include? @club.non_member_banner_url
      assert @response.body.include? @club.non_member_landing_url
      generate_post_get_banner_by_email(@user.email) 
      assert @response.body.include? @club.member_banner_url
      assert @response.body.include? @club.member_landing_url
    end
  end

  test "Should not allow get banner by email for agents that are not admin or api." do
    sign_in @admin_user
    ['representative', 'supervisor', 'agency', 'fulfillment_managment'].each do |role|
      @admin_user.update_attribute :roles, nil
      @admin_user.add_role_with_club(role, @club)
      generate_post_get_banner_by_email("")
      assert_response :unauthorized
    end
  end

  test "Upgrade/Downgrade a User Basic membership level by prorate logic - Provisional User - NewProvisionalDays > OldProvisionalDays" do
    prepare_upgrade_downgrade_toms false

    days_in_provisional = @saved_user.terms_of_membership.provisional_days/2
    middle_of_provisional_days = Time.zone.now.in_time_zone(@saved_user.club.time_zone) + days_in_provisional.days
    nbd = middle_of_provisional_days + @tom_yearly.provisional_days.days

    Timecop.travel(middle_of_provisional_days) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id)
    end

    @saved_user.reload
    assert @saved_user.provisional?
    assert_not_nil @saved_user.operations.where("description like ?", "%Moved next bill date due to Tom change. Already spend #{days_in_provisional} days in previous membership.%").last
    nbd_should_have_set = nbd - days_in_provisional.days
    assert_equal @saved_user.next_retry_bill_date.in_time_zone(@saved_user.club.time_zone).to_date, nbd_should_have_set.to_date, "Expecting #{@saved_user.next_retry_bill_date.to_date} but was #{nbd_should_have_set.to_date}. Dates: #{@saved_user.next_retry_bill_date}. Nbd: #{nbd}. nbd_should_have_set: #{nbd_should_have_set}"
  end

  test "Upgrade a User Basic membership level by prorate logic - Provisional User - NewProvisionalDays > OldProvisionalDays" do
    prepare_upgrade_downgrade_toms false

    days_in_provisional = @saved_user.terms_of_membership.installment_period/2
    middle_of_provisional_days = Time.zone.now.in_time_zone(@saved_user.club.time_zone) + days_in_provisional.days
    nbd = middle_of_provisional_days + @tom_yearly.provisional_days.days
    Timecop.travel(middle_of_provisional_days) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id)
    end

    @saved_user.reload
    assert_not_nil @saved_user.operations.where("description like ?", "%Moved next bill date due to Tom change. Already spend #{days_in_provisional} days in previous membership.%").last
    nbd_should_have_set = nbd - days_in_provisional.days
    assert_equal @saved_user.next_retry_bill_date.in_time_zone(@saved_user.club.time_zone).to_date, nbd_should_have_set.to_date
  end
    
  test "Upgrade/Downgrade User with Basic membership level by prorate logic (NewProvisionalDays > OldProvisionalDays)- Softdecline User (Provisional status)" do
    prepare_upgrade_downgrade_toms false
    previous_membership = @saved_user.current_membership
    sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    active_merchant_stubs(sd_strategy.response_code, "decline stubbed", false)
    
    first_nbd = @saved_user.next_retry_bill_date
    Timecop.travel(first_nbd) do
      @saved_user.bill_membership
    end
    active_merchant_stubs

    rand_date = @saved_user.bill_date + rand(1..6).days
    days_in_provisional = (rand_date.to_date - @saved_user.join_date.to_date).to_i
    nbd = rand_date + @tom_yearly.provisional_days.days
    Timecop.travel(rand_date) do
      generate_post_update_terms_of_membership(@saved_user.id, @tom_yearly.id)
    end
    @saved_user.reload
    assert @saved_user.provisional?

    assert_equal @saved_user.terms_of_membership.id, @tom_yearly.id
    assert_not_nil @saved_user.operations.where("description like ?", "%Moved next bill date due to Tom change. Already spend #{days_in_provisional} days in previous membership.%").last
    nbd_should_have_set = nbd.in_time_zone(@saved_user.club.time_zone) - days_in_provisional.days
    assert_equal @saved_user.next_retry_bill_date.in_time_zone(@saved_user.club.time_zone).to_date, nbd_should_have_set.to_date, "Dates: #{@saved_user.next_retry_bill_date}. Nbd: #{nbd}. nbd_should_have_set: #{nbd_should_have_set}" 
  end

  test "Admin should get user's information" do
    sign_in @admin_user

    @credit_card = FactoryGirl.build :credit_card
    @user = FactoryGirl.build :user_with_api
    @enrollment_info = FactoryGirl.build :membership_with_enrollment_info
    @current_club = @terms_of_membership.club
    @current_agent = @admin_user
    active_merchant_stubs
    generate_post_message

    saved_user = User.find_by email: @user.email
    get_show(saved_user.id)
    assert_response :success
  end
end