FactoryGirl.define do
    # HACK only if using schema as rb instead of sql: 
    # visible_id should be created automatically by mysql.
    # but test database is not created by migrations, so our custom executes
    # are not used. Consequence: visible_id is not auto increment.
    # sequence(:visible_id) {|n| n }

  factory :member do
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    bill_date { DateTime.now }
    birth_date { DateTime.now }
    gender "M"
    status "none"
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :member_with_api, class: Member do
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member_with_api#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    birth_date { DateTime.now }
    gender "M"
    status "none"
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
    association :club, factory: :club_with_api
  end

  factory :member_with_cc, class: Member do
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member_with_cc#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    birth_date { DateTime.now }
    gender "M"
    country "US"
    club_cash_amount 0
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    cohort { Time.zone.now.strftime TEST_COHORT }
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end


  factory :active_member, class: Member do
    status "active"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member_active#{n}@test.no" }
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    type_of_phone_number Settings.type_of_phone_number.home
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
    gender "M"
    blacklisted false
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

  factory :active_member_with_external_id, class: Member do
    status "active"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "active_member_with_external_id#{n}@test.no" }
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    type_of_phone_number Settings.type_of_phone_number.home
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
    gender "M"
    blacklisted false
    credit_cards {|ccs| [ccs.association(:credit_card)]}
    external_id 123456
  end

  factory :active_member_without_cc, class: Member do
    gender "M"
    status "active"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "active_member_without_cc#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :lapsed_member, class: Member do
    gender "M"
    status "lapsed"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "lapsed_member#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    next_retry_bill_date { DateTime.now } 
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    blacklisted false
    cohort { Time.zone.now.strftime TEST_COHORT }
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end


  factory :provisional_member_with_cc, class: Member do
    gender "M"
    status "provisional"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "provisional_member_with_cc#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    cohort { Time.zone.now.strftime TEST_COHORT }
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

  factory :provisional_member, class: Member do
    gender "M"
    status "provisional"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "provisional_member#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
  end

  factory :applied_member, class: Member do
    gender "M"
    status "applied"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "applied_member#{n}@test.no" }
    type_of_phone_number Settings.type_of_phone_number.home
    phone_country_code 123
    phone_area_code 123
    phone_local_number 1234
    birth_date { DateTime.now }
    country "US"
    club_cash_amount 0
    cohort { Time.zone.now.strftime TEST_COHORT }
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

end