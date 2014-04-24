FactoryGirl.define do

  factory :payment_gateway_configuration do
    login "94100010879200000001"
    merchant_key "SAC, Inc"
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
    merchant_key "SAC, Inc"
    password "7RkC6yG74etY545X"
    gateway "authorize_net"
    report_group "SAC_STAGING_TEST"
  end

  factory :first_data_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login  "AE6691-05"
    merchant_key "SAC, Inc"
    password "fJmFbJ3AA"
    gateway "first_data"
    report_group "SAC_STAGING_TEST"
  end
end