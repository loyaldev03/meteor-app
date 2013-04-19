FactoryGirl.define do

  factory :payment_gateway_configuration do
    login "94100010879200000001"
    merchant_key "SAC, Inc"
    password "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU"
    mode "development"
    gateway "mes"
    report_group "SAC_STAGING_TEST"
  end

  factory :litle_payment_gateway_configuration, class: PaymentGatewayConfiguration do
    login "litle"
    merchant_key "SAC, Inc"
    password "SjVFXAYZtUeejfMQnJDblkEEvqkLUvgU"
    mode "development"
    gateway "litle"
    report_group "SAC_STAGING_TEST"
  end

end