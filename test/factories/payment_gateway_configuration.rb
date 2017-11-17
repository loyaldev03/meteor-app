FactoryGirl.define do

  factory :payment_gateway_configuration do
    login "94100010879200000001"
    password "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU"
    gateway "mes"
    report_group "SAC_STAGING_TEST"
  end

  factory :litle_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login "litle"
    merchant_key "SAC, Inc"
    password "a"
    gateway "litle"
    report_group "SAC_STAGING_TEST"
  end

  factory :authorize_net_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  "7g6zBUa54"
    password "7RkC6yG74etY545X"
    gateway "authorize_net"
    report_group "SAC_STAGING_TEST"
  end

  factory :first_data_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  "AE6691-05"
    password "0i5n761o"
    gateway "first_data"
    report_group "SAC_STAGING_TEST"
  end

  factory :stripe_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  "sk_test_qIMzPZXgqG5XafCYgLPSexf4"
    password "a"
    gateway "stripe"
  end

  factory :trust_commerce_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  "3901042"
    password "unacNev8"
    gateway "trust_commerce"
    report_group ""
  end
  
  factory :payeezy_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  'apikey'
    password 'apisecret'
    merchant_key 'token'
    gateway "payeezy"
    report_group ""
    additional_attributes {{js_security_key: 'js_security_key', ta_token: 'ta_token'}}
  end
end