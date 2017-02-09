FactoryGirl.define do

  factory :prospect do
    sequence(:email) {|n| "prospect#{n}@test.no" }
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    state {Faker::Address.state}
    zip 45612 #{ Faker::Address.zip }
    country 'US'
    phone_country_code 123
    phone_area_code 456
    phone_local_number 7894
    ip_address '190.224.250.164'
    user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
    preferences {{ favorite_driver: 'DaleJr', favorite_color: 'red' }}
    product_sku 'SLOOPS'
  end
end