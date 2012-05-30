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
    phone_number { Faker::PhoneNumber.phone_number }
    status "none"
    country "US"
  end

  factory :active_member, class: Member do
    status "active"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    country "US"
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end


  factory :active_member_without_cc, class: Member do
    status "active"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    country "US"
  end

  factory :lapsed_member, class: Member do
    status "lapsed"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    country "US"
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

  factory :provisional_member_with_cc, class: Member do
    status "provisional"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    country "US"
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

  factory :provisional_member, class: Member do
    status "provisional"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    country "US"
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
  end


end