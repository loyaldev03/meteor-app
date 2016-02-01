FactoryGirl.define do

  factory :enrollment_info do
    enrollment_amount 0.5
    source "test"
    product_sku Settings.others_product
    ip_address '190.224.250.164'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
  end

  factory :complete_enrollment_info_with_amount, class: EnrollmentInfo do
    enrollment_amount 0.5
    source "test"
    product_sku Settings.others_product
    ip_address '190.224.250.164'
    campaign_medium 'xyz123456'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
  	mega_channel 'super channel'
  end

  factory :complete_enrollment_info_with_cero_amount, class: EnrollmentInfo do
    source "test"
    enrollment_amount 0.0
    product_sku Settings.others_product
    ip_address '190.224.250.164'
    campaign_medium 'xyz123456'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
    mega_channel 'super channel'
  end

  factory :enrollment_info_with_product_without_stock, class: EnrollmentInfo do
    source "test"
    enrollment_amount 0.5
    product_sku Settings.others_product
    ip_address '190.224.250.164'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
  end  
 
  factory :enrollment_info_with_product_recurrent, class: EnrollmentInfo do
    source "test"
    enrollment_amount 0.5
    product_sku Settings.others_product
    ip_address '190.224.250.164'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
  end   
end