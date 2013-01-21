ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/dsl'
require 'database_cleaner'
require 'mocha'

DatabaseCleaner.strategy = :truncation
# require 'capybara-webkit'

#Capybara.javascript_driver = :webkit
# capybara levanta un server por default
# Capybara.server_port = '8000'
# apybara.app_host = 'http://localhost:8000'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  CREDIT_CARD_TOKEN = { nil => "c25ccfecae10384698a44360444dea", "4012301230123010" => "c25ccfecae10384698a44360444dead8", 
    "5589548939080095" => "c25ccfecae10384698a44360444dead7",
    "340504323632976" => "c25ccfecae10384698a44360444dead6", "123456" => "anytransactioniditsvalid.forinvalidccnumber", 
    "123456789" => "c25ccfecae10384698asddd60444dead6" }


  def active_merchant_stubs(code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, 
      { "transaction_id"=>"c25ccfecae10384698a44360444dead8", "error_code"=> code, 
       "auth_response_text"=>"No Match", "avs_result"=>"N", "auth_code"=>"T5768H" }, 
      { "code"=>"N", "message"=>"Street address and postal code do not match.", 
        "street_match"=>"N", "postal_match"=>"N" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end
  def active_merchant_stubs_store(number = nil, code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { "transaction_id"=>CREDIT_CARD_TOKEN[number], "error_code"=> code, "auth_response_text"=>"No Match" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end

  def create_active_member(tom, member_type = :active_member, enrollment_type = :enrollment_info, member_args = {}, membership_args = {}, use_default_active_merchant_stub = true)
    if use_default_active_merchant_stub
      active_merchant_stubs 
      active_merchant_stubs_store
    end
    membership = FactoryGirl.create("#{member_type}_membership".to_sym, { terms_of_membership: tom }.merge(membership_args))
    active_member = FactoryGirl.create(member_type, { club: tom.club, current_membership: membership }.merge(member_args))
    active_member.memberships << membership
    active_member.save
    ei = FactoryGirl.create(enrollment_type, :member_id => active_member.id) unless enrollment_type.nil?
    membership.enrollment_info = ei
    active_member.reload
    active_member
  end  

end

class ActionController::TestCase
  include Devise::TestHelpers
end

module ActionController
  class IntegrationTest
    include Capybara::DSL

    self.use_transactional_fixtures = false # DOES WORK! Damn it!
  
    #setup do
    #  Capybara.current_driver = :selenium
    #  DatabaseCleaner.start
    #end

    def init_test_setup
      DatabaseCleaner.start
      Capybara.current_driver = :selenium
      #Capybara.current_driver = :webkit
      #Capybara.javascript_driver = nil
      Capybara.default_wait_time = 10
    end

    def sign_in_as(user)
      visit '/'
      fill_in 'agent_login', :with => user.email
      fill_in 'agent_password', :with => user.password
      click_link_or_button('Sign in')
    end

    def do_data_table_search(selector, value)
      within(selector) do
        find(:css,"input[type='text']").set("XXXXXXXXXXXXXXXXXXX")
        sleep(1)
        find(:css,"input[type='text']").set(value)
      end
    end

    def sign_out
      #click_link_or_button('Logout')   
    end

    def confirm_ok_js
      evaluate_script("window.confirm = function(msg) { return true; }")
    end

    def alert_ok_js
      evaluate_script("window.alert = function(msg) { return true; }")
    end

    def select_country_and_state(country = 'US')
      if country == 'US'
        select('United States', :from => 'member[country]')
        within('#states_td'){ select('Alabama', :from => 'member[state]') }
      else
        select('Canada', :from => 'member[country]')
        within('#states_td'){ select('Manitoba', :from => 'member[state]') }
      end
    end

    def search_member(field_selector, value, validate_obj)
      fill_in field_selector, :with => value unless value.nil?
      click_on 'Search'

      within("#members") do
        wait_until {
          assert page.has_content?(validate_obj.status)
          assert page.has_content?("#{validate_obj.visible_id}")
          assert page.has_content?(validate_obj.full_name)
          assert page.has_content?(validate_obj.full_address)
        }

        if !validate_obj.external_id.nil?
          assert page.has_content?(validate_obj.external_id)
        end
      end
    end
        
    def create_member_by_sloop(agent, member, credit_card, enrollment_info, terms_of_membership)
      ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
        Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                        :auth_code => '111', :duplicate => false, 
                                        :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
            ) 
      )
      active_merchant_stubs_store(credit_card.number)
      post( api_members_url , { member: {:first_name => member.first_name, 
                                :last_name => member.last_name,
                                :address => member.address,
                                :gender => 'M',
                                :city => member.city, 
                                :zip => member.zip,
                                :state => member.state,
                                :email => member.email,
                                :country => member.country,
                                :type_of_phone_number => member.type_of_phone_number,
                                :phone_country_code => member.phone_country_code,
                                :phone_area_code => member.phone_area_code,
                                :phone_local_number => member.phone_local_number,
                                :enrollment_amount => enrollment_info.enrollment_amount,
                                :terms_of_membership_id => terms_of_membership.id,
                                :birth_date => member.birth_date,
                                :credit_card => {:number => credit_card.number,
                                                 :expire_month => credit_card.expire_month,
                                                 :expire_year => credit_card.expire_year },
                                :product_sku => enrollment_info.product_sku,
                                :product_description => enrollment_info.product_description,
                                :mega_channel => enrollment_info.mega_channel,
                                :marketing_code => enrollment_info.marketing_code,
                                :fulfillment_code => enrollment_info.fulfillment_code,
                                :ip_address => enrollment_info.ip_address
                                },
                                :api_key => agent.authentication_token, :format => :json})
      assert_response :success
    end

  # Check Refund email -  It is send it by CS inmediate
  def bill_member(member, do_refund = true, refund_amount = nil)
    next_bill_date = member.bill_date + eval(@terms_of_membership_with_gateway.installment_type)

    answer = member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }
    end
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) }


    within("#table_membership_information")do
      wait_until{ assert page.has_content?(I18n.l member.active_credit_card.last_successful_bill_date, :format => :only_date ) } 
    end

    #sleep(5)

    within("#operations") do
      wait_until {
        assert page.has_selector?("#operations_table")
        assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
      }
    end

    within("#transactions") do 
      wait_until {
        assert page.has_selector?("#transactions_table")
        Transaction.all.each do |transaction|
          assert page.has_content?(transaction.full_label.truncate(50))
        end
        # assert page.has_content?("Sale : This transaction has been approved")
        assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
      }
    end

    within("#transactions_table") do
     wait_until{ assert page.has_selector?('#refund') }
    end
    
    if do_refund
      transaction = Transaction.last
      visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id, :transaction_id => transaction.id)

      wait_until{ assert page.has_content?(transaction.amount_available_to_refund.to_s) }

      final_amount = @terms_of_membership_with_gateway.installment_amount.to_s
      final_amount = refund_amount.to_s if not refund_amount.nil?

      fill_in 'refund_amount', :with => final_amount   

      assert_difference ['Transaction.count'] do 
        click_on 'Refund'
      end
      
      within("#operations_table") do 
        wait_until {
          assert page.has_content?("Communication 'Test refund' sent")
          assert page.has_content?("Refund success $#{final_amount}")
        }
      end
      within("#transactions_table") do 
        wait_until {
          assert page.has_content?("Credit : This transaction has been approved")
          assert page.has_content?(final_amount)
        }
      end
      within("#communication") do 
        wait_until {
          assert page.has_content?("Test refund")
          assert page.has_content?("refund")
        }
      end
    end

  end

    teardown do
      DatabaseCleaner.clean
      Capybara.reset_sessions!  
      Capybara.use_default_driver
    end
  end
end

module Airbrake
  def self.notify(exception, opts = {})
    # do nothing.
  end
end


 # use_transactional_fixtures = false    # DOES NOT WORK!
   # … think this should be renamed and should definitely get some documentation love.
    
 