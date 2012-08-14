ENV["RAILS_ENV"] = "test"

require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

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

module Airbrake
  def self.notify(exception, opts = {})
    # do nothing.
  end
end