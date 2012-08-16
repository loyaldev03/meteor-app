ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/dsl'
require 'database_cleaner'

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

    def sign_out
      #click_link_or_button('Logout')   
    end

    def confirm_ok_js
      evaluate_script("window.confirm = function(msg) { return true; }")
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
    
 