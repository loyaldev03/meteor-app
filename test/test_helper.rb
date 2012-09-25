ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/dsl'
require 'database_cleaner'
require 'mocha'
require 'rake'

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

  def active_merchant_stubs(code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, 
      { "transaction_id"=>"c25ccfecae10384698a44360444dead8", "error_code"=> code, 
       "auth_response_text"=>"No Match", "avs_result"=>"N", "auth_code"=>"T5768H" }, 
      { "code"=>"N", "message"=>"Street address and postal code do not match.", 
        "street_match"=>"N", "postal_match"=>"N" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:credit).returns(answer)
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

    def create_member_by_sloop(agent, member, credit_card, enrollment_info, terms_of_membership)
      ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
        Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                        :auth_code => '111', :duplicate => false, 
                                        :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
            ) 
      )
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
    
 