FactoryGirl.define do

  factory :member do
    # HACK: visible_id should be created automatically by mysql.
    # but test database is not created by migrations, so our custom executes
    # are not used. Consequence: visible_id is not auto increment.
    sequence(:visible_id) {|n| n }
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    country "US"
  end

  factory :paid_member, class: Member do
    sequence(:visible_id) {|n| n }
    status "paid"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    country "US"
    association :club
    association :terms_of_membership, factory: :terms_of_membership_with_gateway
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

  factory :lapsed_member, class: Member do
    sequence(:visible_id) {|n| n }
    status "lapsed"
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
    state { Faker::Address.us_state }
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number { Faker::PhoneNumber.phone_number }
    country "US"
    association :club
    association :terms_of_membership, factory: :terms_of_membership_with_gateway
  end

  factory :provisional_member, class: Member do
    sequence(:visible_id) {|n| n }
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
    association :club
    association :terms_of_membership, factory: :terms_of_membership_with_gateway
    credit_cards {|ccs| [ccs.association(:credit_card)]}
  end

end