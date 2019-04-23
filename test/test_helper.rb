ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/dsl'
require 'mocha/setup'
require 'timeout'
require 'tasks/tasks_helpers'
# require 'capybara-screenshot'
# require 'capybara-webkit'

Devise.stretches = 1

## do you use firefox??
Capybara.current_driver = :selenium
## end configuration for firefox
## do you want chrome ? (chrome is for carla)
# Capybara.register_driver :chrome do |app|
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.timeout = 240
#   Capybara::Selenium::Driver.new(app, :browser => :chrome,
#                                  :http_client => client)
# end
# Capybara.javascript_driver = :chrome
# Capybara.current_driver = :chrome
## end chrome configuration

Capybara.default_max_wait_time = 10

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || ConnectionPool::Wrapper.new(size: 1) { retrieve_connection }
  end
end

ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  setup do
    stubs_elasticsearch_index
    stub_mailchimp
  end

  def unstubs_elasticsearch_index
    Tire::Index.any_instance.unstub(:store)
    Tire::Index.any_instance.unstub(:store)
  end

  def stubs_elasticsearch_index
    Tire::Index.any_instance.stubs(:store).returns('ok' => true)
    Tire::Index.any_instance.stubs(:store).returns('ok' => true)
  end

  def stub_spree_user_create(status = 200)
    body = if status == 200
             { 'uid' => '123456789', 'urllogin' => 'https://testing.com/urllogin' }
           else
             { 'message': 'error message' }
           end

    response = Faraday::Response.new(body: body, status: status)
    Faraday::Connection.any_instance.stubs(:post).returns(response)
  end

  def stub_spree_user_update(status = 200)
    body = if status == 200
             { 'uid' => '123456789' }
           else
             { 'message': 'error message' }
           end
    response = Faraday::Response.new(body: body, status: status)
    Faraday::Connection.any_instance.stubs(:put).returns(response)
  end

  def stub_mailchimp
    answer = Gibbon::Response.new(body: { 'id' => '85c4a5155adbba664e2757c7cde53ba7', 'email_address' => 'pepemari@hotmail.com', 'unique_email_id' => '273ebe7b0e', 'email_type' => 'html', 'status' => 'subscribed', 'merge_fields' => { 'FNAME' => 'tonu', 'LNAME' => 'ujyyhh', 'CITY' => 'city', 'STATUS' => 'provisional', 'TOMID' => 376, 'MSINCEDATE' => '2019-03-11', 'JOINDATE' => '2019-03-11', 'CANCELDATE' => ' ', 'AUDIENCE' => 'all', 'ZIP' => '65941', 'CTYPE' => 'sloop', 'MEDIUM' => 'display', 'PRODUCTSKU' => 'NTWOTONEMUGTONYSTEWART', 'EAMOUNT' => 1.95, 'IAMOUNT' => 14.95, 'BILLDATE' => '2019-04-10', 'EXTERNALID' => ' ', 'GENDER' => ' ', 'PHONE' => '+1 (123) 1233122', 'BIRTHDATE' => ' ', 'PREF1' => 'Wallace, Mike', 'PREF2' => ' ', 'PREF3' => ' ', 'STATE' => 'MA', 'LANDINGURL' => 'http://membertest.onmc.com/select-with-images?utm_campaign=sloop&utm_source=facebook&utm_medium=display&utm_content=banner_some&audience=all&campaign_code=xeeb2clomqu3af4q', 'PREF4' => ' ', 'CJOINDATE' => '2019-03-11', 'MEMBERID' => '11349964381', 'ADDRESS' => '12 th address', 'VIPMEMBER' => 'false' }, 'stats' => { 'avg_open_rate' => 0, 'avg_click_rate' => 0 }, 'ip_signup' => ' ', 'timestamp_signup' => ' ', 'ip_opt' => '50.116.16.84', 'timestamp_opt' => '2019-03-11T13:19:11+00:00', 'member_rating' => 2, 'last_changed' => '2019-03-11T13:19:11+00:00', 'language' => ' ', 'vip' => false, 'email_client' => ' ', 'location' => { 'latitude' => 0, 'longitude' => 0, 'gmtoff' => 0, 'dstoff' => 0, 'country_code' => ' ', 'timezone' => ' ' }, 'tags_count' => 0, 'tags' => [], 'list_id' => 'd38bcbca86', '_links' => [{ 'rel' => 'self', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json' }, { 'rel' => 'parent', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json' }, { 'rel' => 'update', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'PATCH', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PATCH.json' }, { 'rel' => 'upsert', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'PUT', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PUT.json' }, { 'rel' => 'delete', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'DELETE' }, { 'rel' => 'activity', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/activity', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Activity/Response.json' }, { 'rel' => 'goals', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/goals', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Goals/Response.json' }, { 'rel' => 'notes', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/notes', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Notes/CollectionResponse.json' }, { 'rel' => 'delete_permanent', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/actions/delete-permanent', 'method' => 'POST' }] })
    Gibbon::Request.any_instance.stubs(:retrieve).returns(answer)
    Gibbon::Request.any_instance.stubs(:create).returns(answer)
    Gibbon::Request.any_instance.stubs(:update).returns(answer)
  end

  def stub_mailchimp_with_error
    answer = Gibbon::MailChimpError.new({}, status_code: 404, body: { 'type' => 'http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/', 'title' => 'Resource Not Found', 'status' => 404, 'detail' => 'The requested resource could not be found.', 'instance' => '' })
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
    Gibbon::Request.any_instance.stubs(:create).returns(answer)
    Gibbon::Request.any_instance.stubs(:update).returns(answer)
  end

  CREDIT_CARD_TOKEN = { nil => 'c25ccfecae10384698a44360444dea', '4012301230123010' => 'c25ccfecae10384698a44360444dead8',
    '5589548939080095' => 'c25ccfecae10384698a44360444dead7',
    '340504323632976' => 'c25ccfecae10384698a44360444dead6', '123456' => 'anytransactioniditsvalid.forinvalidccnumber',
    '123456789' => 'c25ccfecae10384698asddd60444dead6', '4000060001234562' => '8748333042191111', '340000000000009' => '032315636746108',
    '5199701234567892' => '9729852103506619', '4111111111111111' => '9782465740991323' }

  def active_merchant_stubs(code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message,
      { 'transaction_id' => 'c25ccfecae10384698a44360444dead8', 'error_code' => code,
       'auth_response_text' => 'No Match', 'avs_result' => 'N', 'auth_code' => 'T5768H' },
      { 'code' => 'N', 'message' => 'Street address and postal code do not match.',
        'street_match' => 'N', 'postal_match' => 'N' })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_litle(code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message,
      { 'litleOnlineResponse' => { 'message' => 'Valid Format', 'saleResponse' => { 'response' => code }, 'response' => code, 'version' => '8.16',
       'xmlns' => 'http://www.litle.com/schema', 'registerTokenResponse' => { 'customerId' => '', 'id' => '',
       'reportGroup' => 'Default Report Group', 'litleTxnId' => '630745122415368266',
       'litleToken' => '1111222233334444', 'response' => '000', 'responseTime' => '2013-04-08T16:54:24',
       'message' => 'Approved' } } })
    ActiveMerchant::Billing::LitleGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::LitleGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::LitleGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::LitleGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_auth_net(code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message,
      { 'response_code' => code, 'response_reason_code' => '6', 'response_reason_text' => message,
       'avs_result_code' => 'P', 'transaction_id' => '0', 'card_code' => '', 'action' => 'AUTH_CAPTURE' })
    ActiveMerchant::Billing::AuthorizeNetGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::AuthorizeNetGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::AuthorizeNetGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::AuthorizeNetGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_first_data(code = '000', message = 'This transaction has been approved with stub', success = true)
    # ActiveMerchant::Billing::Response:0xbbf5350 @params={"transaction_approved"=>"false", "error_number"=>"400", "error_description"=>"Bad Request (22) - Invalid Credit Card Number"}, @message="Bad Request (22) - Invalid Credit Card Number", @success=false, @test=true, @authorization="", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>
    answer = ActiveMerchant::Billing::Response.new(success, message,
      'bank_resp_code' => code, 'error_description' => message, 'response_auth_code' => 'a',
      'transaction_tag' => '0', 'card_code' => '', 'action' => 'AUTH_CAPTURE', 'transarmor_token' => '0755125953951111')
    ActiveMerchant::Billing::FirstdataE4Gateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::FirstdataE4Gateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::FirstdataE4Gateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::FirstdataE4Gateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_trust_commerce(code = 'approved', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { 'transid' => '028-0168943221', 'status' => code, 'billingid' => 'S50XKP' })
    ActiveMerchant::Billing::TrustCommerceGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::TrustCommerceGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::TrustCommerceGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::TrustCommerceGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_store_payeezy(code = '100', message = 'Transaction Normal - Approved with Stub', success = true, credit_card_number = 340000000000009)
    response = if success
      { 'correlation_id' => '228.1085182325738', 'status' => 'success', 'type' => 'FDToken',
      'token' => { 'type' => 'Mastercard', 'cardholder_name' => 'test test', 'exp_date' => '0320',
      'value' => CREDIT_CARD_TOKEN[credit_card_number] } }
    else
      { 'status' => 'declined', 'Error' => { 'messages' => [{ 'code' => code }] } }
    end
    answer = ActiveMerchant::Billing::Response.new(success, message, response, authorization: "Mastercard|test test|0320|#{CREDIT_CARD_TOKEN[credit_card_number]}")
    ActiveMerchant::Billing::PayeezyGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_payeezy(code = '100', message = 'Transaction Normal - Approved with Stub', success = true, credit_card_number = 340000000000009)
    active_merchant_stubs_store_payeezy(code, message, success, credit_card_number)
    response = { 'correlation_id' => '228.5060252765196', 'transaction_status' => (success ? 'approved' : 'declined'),
                'validation_status' => 'success', 'transaction_type' => 'purchase', 'transaction_id' => 'ET131616',
                'transaction_tag' => '2218270190', 'method' => 'token', 'amount' => '100', 'currency' => 'USD',
                'cvv2' => 'I', 'token' => { 'token_type' => 'FDToken', 'token_data' => { 'value' => '1072051183520026', 'type' => 'Visa', 'cardholder_name' => 'sebastian testing', 'exp_date' => '0318', 'value' => '2175871555790026' } },
                'bank_resp_code' => code, 'bank_message' => 'Approved', 'gateway_resp_code' => '00',
                'gateway_message' => 'Transaction Normal' }
    answer = ActiveMerchant::Billing::Response.new(success, message, response, authorization: 'ET131616|2218270190|token|100')
    ActiveMerchant::Billing::PayeezyGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::PayeezyGateway.any_instance.stubs(:authorize).returns(answer)
    refund_answer = ActiveMerchant::Billing::Response.new(success, message, response, authorization: 'RETURN|2218270190|direct_debit|100')
    ActiveMerchant::Billing::PayeezyGateway.any_instance.stubs(:refund).returns(refund_answer)
  end

  def active_merchant_stubs_store(number = nil, code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { 'transaction_id' => CREDIT_CARD_TOKEN[number], 'error_code' => code, 'auth_response_text' => 'No Match' })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end

  def active_merchant_stubs_purchase(number = nil, code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { 'transaction_id' => CREDIT_CARD_TOKEN[number], 'error_code' => code, 'auth_response_text' => 'No Match' })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
  end

  def active_merchant_stubs_process(number = nil, code = '000', message = 'This transaction has been approved with stub', success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { 'transaction_id' => CREDIT_CARD_TOKEN[number], 'error_code' => code, 'auth_response_text' => 'No Match' })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:process).returns(answer)
  end

  def active_merchant_stubs_stripe(code = nil, message = 'This transaction has been approved with stub', success = true)
    answer_store = ActiveMerchant::Billing::Response.new(success, message, { 'object' => 'customer', 'created' => 1438698687, 'id' => 'cus_6jZb5Ha7COWQeu', 'livemode' => false, 'description' => nil, 'email' => 'user1@test.no', 'delinquent' => false, 'metadata' => {}, 'subscriptions' => { 'object' => 'list', 'total_count' => 0, 'has_more' => false, 'url' => '/v1/customers/cus_6jZb5Ha7COWQeu/subscriptions', 'data' => [] }, 'discount' => nil, 'account_balance' => 0, 'currency' => nil, 'sources' => { 'object' => 'list', 'total_count' => 1, 'has_more' => false, 'url' => '/v1/customers/cus_6jZb5Ha7COWQeu/sources', 'data' => [{ 'id' => 'card_16W6RvHrcw1MEee7uPRq2cqR', 'object' => 'card', 'last4' => '4242', 'brand' => 'Visa', 'funding' => 'credit', 'exp_month' => 10, 'exp_year' => 2017, 'fingerprint' => 'oR2du9mINXNGpmF4', 'country' => 'US', 'name' => 'Lauriane Bednar', 'address_line1' => nil, 'address_line2' => nil, 'address_city' => nil, 'address_state' => nil, 'address_zip' => nil, 'address_country' => nil, 'cvc_check' => nil, 'address_line1_check' => nil, 'address_zip_check' => nil, 'tokenization_method' => nil, 'dynamic_last4' => nil, 'metadata' => {}, 'customer' => 'cus_6jZb5Ha7COWQeu' }] }, 'default_source' => 'card_16W6RvHrcw1MEee7uPRq2cqR' })
    answer = if code
      ActiveMerchant::Billing::Response.new(success, message, { 'id' => 'ch_16W6VMHrcw1MEee7FAOihpRK', 'status' => code })
    else
      ActiveMerchant::Billing::Response.new(success, message, { 'id' => 'ch_16W6VMHrcw1MEee7FAOihpRK', 'object' => 'charge', 'created' => 1438698900, 'livemode' => false, 'paid' => true, 'status' => 'succeeded', 'amount' => 10000, 'currency' => 'usd', 'refunded' => false, 'source' => { 'id' => 'card_16W6VJHrcw1MEee7rLFnC0Io', 'object' => 'card', 'last4' => '4242', 'brand' => 'Visa', 'funding' => 'credit', 'exp_month' => 10, 'exp_year' => 2017, 'fingerprint' => 'oR2du9mINXNGpmF4', 'country' => 'US', 'name' => 'Lauriane Bednar', 'address_line1' => nil, 'address_line2' => nil, 'address_city' => nil, 'address_state' => nil, 'address_zip' => nil, 'address_country' => nil, 'cvc_check' => nil, 'address_line1_check' => nil, 'address_zip_check' => nil, 'tokenization_method' => nil, 'dynamic_last4' => nil, 'metadata' => {}, 'customer' => 'cus_6jZb5Ha7COWQeu' }, 'captured' => true, 'balance_transaction' => 'txn_16W6VMHrcw1MEee7Eecakr8z', 'failure_message' => nil, 'failure_code' => nil, 'amount_refunded' => 0, 'customer' => 'cus_6jZb5Ha7COWQeu', 'invoice' => nil, 'description' => nil, 'dispute' => nil, 'metadata' => {}, 'statement_descriptor' => nil, 'fraud_details' => {}, 'receipt_email' => nil, 'receipt_number' => nil, 'shipping' => nil, 'destination' => nil, 'application_fee' => nil, 'refunds' => { 'object' => 'list', 'total_count' => 0, 'has_more' => false, 'url' => '/v1/charges/ch_16W6VMHrcw1MEee7FAOihpRK/refunds', 'data' => [] } })
    end

    ActiveMerchant::Billing::StripeGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::StripeGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::StripeGateway.any_instance.stubs(:store).returns(answer_store)
  end

  def product_variant_stock_management_stubs_store
    answer = Hashie::Mash.new({ status: 200, body: { code: 200, data: { campaigns_backorderable: true, id: 6, name: 'testing name', sku: 'TESTINGSKU', stock: 15, weight: '3.0', image_url: 'https://s3.amazonaws.com/sacdailydealsonmcdev/app/public/spree/products/74/product/favicon.jpg?1489696964' } } })
    Faraday::Connection.any_instance.stubs(:post).returns(answer)
  end

  def create_active_user(tom, user_type = :active_user, enrollment_type = :enrollment_info, user_args = {}, membership_args = {}, use_default_active_merchant_stub = true)
    if use_default_active_merchant_stub
      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true)
    end

    membership = FactoryBot.create("#{user_type}_membership", { terms_of_membership: tom }.merge(membership_args))
    active_user = FactoryBot.create(user_type, { club: tom.club, current_membership: membership }.merge(user_args))
    active_user.active_credit_card.update_attribute :gateway, tom.club.payment_gateway_configurations.first.gateway if active_user.active_credit_card
    active_user.memberships << membership
    active_user.current_membership = membership
    active_user.save
    active_user
  end

  def enroll_user(user, tom, amount=23, cc_blank=false, credit_card = FactoryBot.build(:credit_card), product_sku = Settings.others_product)
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    answer = User.enroll(tom, nil, amount,
      { first_name: user.first_name,
        last_name: user.last_name, address: user.address, city: user.city, gender: 'M',
        zip: user.zip, state: user.state, email: user.email, type_of_phone_number: user.type_of_phone_number,
        phone_country_code: user.phone_country_code, phone_area_code: user.phone_area_code,
        phone_local_number: user.phone_local_number, country: 'US',
        product_sku: product_sku },
      { number: credit_card.number,
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)
    assert (answer[:code] == Settings.error_codes.success), answer[:message] + answer.inspect
    saved_user = User.find(answer[:member_id])
    assert_not_nil saved_user
    assert_not_nil saved_user.join_date, 'join date should not be nil'
    assert_equal saved_user.status, (tom.needs_enrollment_approval ? 'applied' : 'provisional')
    saved_user
  end

  def excecute_like_server(club_timezone)
    Time.zone = 'UTC'
    yield
    Time.zone = club_timezone
  end
end

class ActionController::TestCase
  include Devise::TestHelpers

  setup do
    stubs_elasticsearch_index
  end
end

def perform_call_as(agent)
  sign_in agent
  yield
  sign_out agent
end

def sign_agent_with_global_role(type)
  @agent = FactoryBot.create type
  sign_in @agent
end

def sign_agent_with_club_role(type, role, club_id = nil)
  @agent = FactoryBot.create(type, roles: '')
  ClubRole.create(club_id: (club_id || @club.id), agent_id: @agent.id, role: role)
  sign_in @agent
end

module ActionDispatch
  class IntegrationTest
    include Capybara::DSL

    self.use_transactional_fixtures = true

    def setup
      stubs_elasticsearch_index
      FactoryBot.create(:batch_agent, id: 1) unless Agent.find_by(email: Settings.batch_agent_email)
      page.driver.browser.manage.window.resize_to(1024, 720)
    end

    def teardown
      sleep 5
      Capybara.reset_sessions!
    end

    def sign_in_as(user)
      visit '/'
      within('#new_agent') do
        fill_in 'agent_email', with: user.email
        fill_in 'agent_password', with: user.password
      end
      click_link_or_button('Log in')
    end

    def sign_agent_with_club_role(type, role)
      @agent = FactoryBot.create(type, roles: '')
      ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
      sign_in_as(@agent)
    end

    def wait_until
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep(0.1) until value = yield
        value
      end
    end

    def do_data_table_search(selector, value)
      within(selector) do
        find(:css, "input[type='search']").set(value)
      end
    end

    def sign_out
      click_link_or_button('link_logout')
    end

    def confirm_ok_js
      page.execute_script("$('.modal .commit').click();")
    end

    def confirm_javascript_ok
      evaluate_script('window.confirm = function(msg) { return true; }')
    end

    def alert_ok_js
      evaluate_script('window.alert = function(msg) { return true; }')
    end

    def select_into_dropdown(field, value)
      page.execute_script("$('#{field} option:contains(' + '#{value}' + ')').attr('selected', 'selected'); $('#{field}').change();")
    end

    def select_country_and_state(country = 'US')
      if country == 'US'
        select('United States', from: 'user[country]')
        within('#states_td') { select('Alabama', from: 'user[state]') }
      else
        select('Canada', from: 'user[country]')
        within('#states_td') { select('Manitoba', from: 'user[state]') }
      end
    end

    def create_user_by_sloop(agent, user, credit_card, membership, terms_of_membership, validate = true, cc_blank = false)
      membership ||= FactoryBot.build(:membership_with_enrollment_info)
      if cc_blank
        credit_card_to_load = FactoryBot.build(:blank_credit_card)
      elsif credit_card.nil?
        credit_card_to_load = FactoryBot.build(:credit_card)
      else
        credit_card_to_load = credit_card
      end

      active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card_to_load.number)
      post(api_members_url, { member: { first_name: user.first_name,
                                        last_name: user.last_name,
                                        address: user.address,
                                        gender: 'M',
                                        city: user.city,
                                        zip: user.zip,
                                        state: user.state,
                                        email: user.email,
                                        country: user.country,
                                        type_of_phone_number: user.type_of_phone_number,
                                        phone_country_code: user.phone_country_code,
                                        phone_area_code: user.phone_area_code,
                                        phone_local_number: user.phone_local_number,
                                        enrollment_amount: membership.enrollment_amount,
                                        terms_of_membership_id: terms_of_membership.id,
                                        birth_date: user.birth_date,
                                        credit_card: { number: credit_card_to_load.number,
                                                       expire_month: credit_card_to_load.expire_month,
                                                       expire_year: credit_card_to_load.expire_year },
                                        product_sku: membership.product_sku,
                                        product_description: membership.product_description,
                                        utm_campaign: membership.utm_campaign,
                                        audience: membership.audience,
                                        campaign_id: membership.campaign_code,
                                        ip_address: membership.ip_address
                                      }, setter: { cc_blank: cc_blank },
                              api_key: agent.authentication_token, format: :json })
      assert_response :success if validate
      User.find_by(email: user.email, club_id: terms_of_membership.club_id)
    end

    def select_from_datepicker(name, date)
      sleep 1
      page.execute_script("window.jQuery('#"+name+"').next().click()")
      within('#ui-datepicker-div') do
        while (within('.ui-datepicker-year') { page.has_no_content?(date.year) })
          find('.ui-icon-circle-triangle-e').click
        end
        while (within('.ui-datepicker-month') { page.has_no_content?(date.strftime('%B')) })
          find('.ui-icon-circle-triangle-e').click
        end
        first(:link, date.day.to_s, exact: true).click
      end
      date
    end

    def fill_in_user(unsaved_user, credit_card = nil, tom_type = nil, cc_blank = false, product_sku = Settings.others_product)
      visit new_user_path(partner_prefix: unsaved_user.club.partner.prefix, club_prefix: unsaved_user.club.name)
      credit_card          ||= FactoryBot.build(:credit_card_master_card)
      type_of_phone_number = (unsaved_user[:type_of_phone_number].blank? ? '' : unsaved_user.type_of_phone_number.capitalize)

      within('#table_demographic_information') do
        fill_in 'user[first_name]', with: unsaved_user.first_name
        if %w[Male M].include? unsaved_user.gender
          select('Male', from: 'user[gender]')
        elsif %w[Female F].include? unsaved_user.gender
          select('Female', from: 'user[gender]')
        end
        fill_in 'user[address]', with: unsaved_user.address
        select_country_and_state(unsaved_user.country)
        fill_in 'user[city]', with: unsaved_user.city
        fill_in 'user[last_name]', with: unsaved_user.last_name
        fill_in 'user[zip]', with: unsaved_user.zip
      end
      # If you want create user with enrollment_fee use next sentence.
      # page.execute_script("$('#user_enrollment_amount').val('0.5').change();")
      # find(:xpath, "//input[@id='user_enrollment_amount']", :visible => false).value

      # page.execute_script("window.jQuery('#birt_date').next().click()")
      # within("#ui-datepicker-div") do
      #     if ((Time.zone.now+2.day).month != Time.zone.now.month)
      #       find(".ui-icon-circle-triangle-e").click
      #     end
      #     first(:link, "#{(Time.zone.now+1.day).day}").click
      #   end
      # end

      within('#table_contact_information') do
        fill_in 'user[phone_country_code]', with: unsaved_user.phone_country_code
        fill_in 'user[phone_area_code]', with: unsaved_user.phone_area_code
        fill_in 'user[phone_local_number]', with: unsaved_user.phone_local_number
        select(type_of_phone_number, from: 'user[type_of_phone_number]')
        fill_in 'user[email]', with: unsaved_user.email
      end

      if tom_type
        within('#table_contact_information') do
          select(tom_type, from: 'user[terms_of_membership_id]')
        end
      end

      fill_in_credit_card_info(credit_card, cc_blank)

      if unsaved_user.club.requires_external_id and not unsaved_user.external_id.nil?
        fill_in 'user[external_id]', with: unsaved_user.external_id
      end

      unless product_sku.blank?
        select(product_sku, from: 'product_sku')
      end

      alert_ok_js
      click_link_or_button 'Create User'
    end

    def fill_in_credit_card_info(credit_card, cc_blank = false)
      if cc_blank
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, '0000000000')
        within('#table_credit_card') do
          check 'setter[cc_blank]'
        end
      else
        active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
        within('#table_credit_card') do
          fill_in 'user[credit_card][number]', with: credit_card.number
          select credit_card.expire_month.to_s, from: 'user[credit_card][expire_month]'
          select credit_card.expire_year.to_s, from: 'user[credit_card][expire_year]'
        end
      end
    end

    def create_user(unsaved_user, credit_card = nil, tom_type = nil, cc_blank = false, product_sku = Settings.others_product)
      fill_in_user(unsaved_user, credit_card, tom_type, cc_blank, product_sku)
      begin
        wait_until { assert find_field('input_first_name').value == unsaved_user.first_name }
      rescue
        Rails.logger.error 'Error - '
        Rails.logger.error page.inspect
      end
      User.find_by_email(unsaved_user.email)
    end

    # Check Refund email -  It is send it by CS inmediate
    def bill_user(user)
      active_merchant_stubs_payeezy
      Time.zone                             = user.club.time_zone
      diff_between_next_bill_date_and_today = user.next_retry_bill_date - Time.zone.now
      next_bill_date                        = user.next_retry_bill_date + user.terms_of_membership.installment_period.days
      user.update_attribute(:next_retry_bill_date, Time.zone.now)

      Time.zone = 'UTC'
      answer    = user.reload.bill_membership
      Time.zone = user.club.time_zone
      user.update_attribute(:next_retry_bill_date, user.next_retry_bill_date + diff_between_next_bill_date_and_today)
      assert (answer[:code] == Settings.error_codes.success), answer[:message]

      visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
      within('#table_membership_information') do
        find('#td_mi_next_retry_bill_date', text: I18n.l(next_bill_date, :format => :only_date))
        assert page.has_content?(I18n.l user.active_credit_card.last_successful_bill_date, :format => :only_date)
      end

      within('.nav-tabs') { click_on 'Operations' }
      within('#operations') { assert page.has_content?("Member billed successfully $#{user.terms_of_membership.installment_amount}") }

      within('.nav-tabs') { click_on 'Transactions' }
      within('#transactions') do
        assert page.has_selector?('#transactions_table')
        Transaction.all.each do |transaction|
          assert(page.has_content?('Transaction Normal - Approved with Stub') || page.has_content?('Sale : This transaction has been approved with stub'))
        end
        assert page.has_content?(user.terms_of_membership.installment_amount.to_s)
      end

      within('#transactions_table') { assert page.has_selector?('#refund') }
      user.transactions.where('operation_type = 101').order(:created_at).last
    end

    def add_club_cash(user, amount, description, validate = true)
      previous_amount = user.club_cash_amount
      new_amount = previous_amount + amount
      visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
      wait_until { assert find_field('input_first_name').value == user.first_name }
      within('#table_membership_information') { click_on 'Add club cash' }
      find('tr', text: I18n.t('activerecord.attributes.club_cash_transaction.amount_help'))

      alert_ok_js
      fill_in 'club_cash_transaction[amount]', with: amount
      fill_in 'club_cash_transaction[description]', with: description
      click_on 'Save club cash transaction'
      sleep 1
      if validate
        within('.nav-tabs') { click_on 'Operations' }
        within('#operations_table') { assert page.has_content?("#{amount.to_f.abs} club cash was successfully #{amount > 0 ? 'added' : 'deducted'}. Concept: #{description}")}
        within('.nav-tabs') { click_on 'Club Cash' }
        within('#td_mi_club_cash_amount') { assert page.has_content?(new_amount.to_s) }
      else
        confirm_ok_js
      end
    end

    def recover_user(user,new_tom, validate = true)
      visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
      wait_until{ assert find_field('input_first_name').value == user.first_name }
      click_link_or_button 'Recover'
      select(new_tom.name, from: 'terms_of_membership_id')
      click_on 'Recover'
      confirm_ok_js
      if validate
        wait_until{ assert find_field('input_first_name').value == user.first_name }
        assert page.has_content? 'Member recovered successfully'
      end
    end

    def set_as_undeliverable_user(user, reason = 'Undeliverable', validate = true)
      visit user_set_undeliverable_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: user.id)
      within('#undeliverable_table') { fill_in reason, with: reason }
      click_link_or_button 'Set wrong address'
      confirm_ok_js

      if validate
        sleep(1)
        within('.nav-tabs') { click_on 'Operations' }
        within('#operations') { assert page.has_content?("Address #{user.reload.full_address} is undeliverable. Reason: #{reason}")}
        within('#table_demographic_information') { assert page.has_css?('tr.yellow') }
        assert_equal user.wrong_address, reason
      end
    end

    def search_fulfillments(all_times = false, initial_date = nil, end_date = nil, status = nil, type = 'sloops', sku = nil)
      visit fulfillments_index_path(partner_prefix: @partner.prefix, club_prefix: @club.name)
      within('#fulfillments_table') do
        check 'all_times' if all_times

        unless initial_date.nil?
          months_difference = initial_date.month - Time.zone.now.month
          within('#td_initial_date') do
            page.execute_script("window.jQuery('#end_date').next().click()")
            within('.ui-datepicker-div') do
              if months_difference > 0
                months_difference.times { click('ui-datepicker-next') }
              elsif months_difference < 0
                months_difference.times { click('ui-datepicker-prev') }
              end

              within('.ui-datepicker-calendar') { click_on(initial_date.day) }
            end
          end
        end

        unless end_date.nil?
          months_difference = end_date.month - Time.zone.month
          within('#td_end_date') do
            page.execute_script("window.jQuery('#end_date').next().click()")
            if months_difference > 0
              within('.ui-datepicker-div') { months_difference.times { click('ui-datepicker-next') } }
            elsif months_difference < 0
              within('.ui-datepicker-div') { months_difference.times { click('ui-datepicker-prev') } }
            end
            within('.ui-datepicker-div') do
              within('.ui-datepicker-calendar') { click_on(end_date.day) }
            end
          end
        end

        select status, from: 'status' unless status.nil?
        unless type.nil?
          if type == 'sloops'
            find(:css, "#radio_product_filter_[value='']").set(true)
          else
            fill_in 'input_product_filter', with: type
          end
        end
      end

      unless sku.nil?
        find(:css, '#radio_product_filter_sku').set(true)
        fill_in 'input_product_filter', with: sku
      end

      click_link_or_button 'Report'
    end

    def update_status_on_fulfillments(fulfillments, new_status, all = false, validate = true)
      previous_status = fulfillments.first.status
      within('#report_results') do
        select new_status, from: 'new_status'
        if ['returned','bad_address'].include? new_status
          fill_in 'reason', with: 'Reason to change.'
        end

        if all
          check 'fulfillment_select_all'
        else
          fulfillments.each do |fulfillment|
            check "fulfillment_selected[#{fulfillment.id}]"
          end
        end

        click_link_or_button 'Update status'

        if validate
          fulfillments.each do |fulfillment|
            find('tr', text: "Changed status on Fulfillment ##{fulfillment.id} #{fulfillment.product_sku} from #{previous_status} to #{new_status}")
          end
        end
      end
    end

    def validate_view_user_base(user, status='provisional')
      visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
      wait_until { assert find_field('input_first_name').value == user.first_name }

      assert find_field('input_id').value == user.id.to_s
      assert find_field('input_first_name').value == user.first_name
      assert find_field('input_last_name').value == user.last_name
      assert find_field('input_gender').value == (user.gender == 'F' ? 'Female' : 'Male') unless user.gender.blank?
      assert find_field('input_member_group_type').value == (user.member_group_type.nil? ? I18n.t('activerecord.attributes.user.not_group_associated') : user.member_group_type.name)

      within('#table_demographic_information') do
        assert page.has_content?(user.address)
        assert page.has_content?(user.city)
        assert page.has_content?(user.state)
        assert page.has_content?(user.country)
        assert page.has_content?(user.zip)
        assert page.has_selector?('#link_user_set_undeliverable')
      end

      within('#table_contact_information') do
        assert page.has_content?(user.full_phone_number)
        assert page.has_content?(user.type_of_phone_number.capitalize)
        assert page.has_content?(user.birth_date.to_s)
        assert page.has_selector?('#link_user_set_unreachable')
      end

      active_credit_card = user.active_credit_card
      within('#table_active_credit_card') do
        wait_until { assert page.has_content?(active_credit_card.last_digits.to_s) }
        if active_credit_card.cc_type.nil?
          wait_until { assert page.has_content?(I18n.t('activerecord.attributes.credit_card.type_unknown')) }
        else
          wait_until { assert page.has_content?(active_credit_card.cc_type.to_s) }
        end
        wait_until { assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}") }
        wait_until { assert page.has_content?(I18n.l(active_credit_card.created_at, :format => :only_date)) }
      end

      within('#table_membership_information') do

        within('#td_mi_status') { assert page.has_content?(status) }

        within('#td_mi_member_since_date') { assert page.has_content?(I18n.l(user.member_since_date, :format => :only_date)) }

        assert page.has_content?(user.terms_of_membership.name)

        assert page.has_content?(user.current_membership.created_by.username)

        within('#td_mi_recycled_times') { assert page.has_content?(user.recycled_times.to_s) }

        assert page.has_no_selector?('#td_mi_external_id')

        within('#td_mi_join_date') { assert page.has_content?(I18n.l(user.join_date, :format => :only_date)) }

        within('#td_mi_next_retry_bill_date') { assert page.has_content?(I18n.l(user.next_retry_bill_date, :format => :only_date)) } unless ['applied', 'lapsed'].include? user.status

        assert page.has_selector?('#link_user_change_next_bill_date') unless ['applied', 'lapsed'].include? user.status

        within('#td_mi_club_cash_amount') { assert page.has_content?("#{user.club_cash_amount.to_f}") }

        assert page.has_selector?('#link_user_add_club_cash') if user.status == 'provisional' || user.status == 'active'
      end
      if not user.current_membership.nil?
        if user.current_membership.product and not user.status == 'applied'
          within('.nav-tabs') { click_on 'Fulfillments' }
          within('#fulfillments') do
            assert page.has_content?(user.current_membership.product.sku)
          end
        end
      end
      membership = user.current_membership

      within('.nav-tabs') { click_on 'Memberships' }
      within('#memberships_table') do
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(status)
      end
    end
  end
end

module Airbrake
  def self.notify(exception, opts = {})
    # do nothing.
  end
end
