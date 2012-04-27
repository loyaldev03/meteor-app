FactoryGirl.define do

  factory :member do
    # HACK: visible_id should be created automatically by mysql.
    # but test database is not created by migrations, so our custom executes
    # are not used. Consequence: visible_id is not auto increment.
    sequence(:visible_id) {|n| n }
    first_name "first"
    last_name "last"
    address "peron 3455"
    city "test"
    zip "345677"
    state "CT"
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number "237264827652"
    country "US"
    association :club
    association :terms_of_membership
  end

  factory :lapsed_member, class: Member do
    sequence(:visible_id) {|n| n }
    status "lapsed"
    first_name "first"
    last_name "last"
    address "peron 3455"
    city "test"
    zip "345677"
    state "CT"
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number "237264827652"
    country "US"
    association :club
    association :terms_of_membership
  end

  factory :provisional_member, class: Member do
    sequence(:visible_id) {|n| n }
    status "provisional"
    first_name "first"
    last_name "last"
    address "peron 3455"
    city "test"
    zip "345677"
    state "CT"
    sequence(:email) {|n| "member#{n}@test.no" }
    phone_number "237264827652"
    country "US"
    join_date { DateTime.now }
    next_retry_bill_date { DateTime.now } 
    bill_date { DateTime.now }
    association :club
    association :terms_of_membership
  end

end