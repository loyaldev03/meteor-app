FactoryGirl.define do

  factory :member do
    # HACK: visible_id should be created automatically by mysql.
    # but test database is not created by migrations, so our custom executes
    # are not used. Consequence: visible_id is not auto increment.
    visible_id 23
    first_name "first"
    last_name "last"
    address "peron 3455"
    city "test"
    zip "345677"
    state "CT"
    email "carla@test.com.ar"
    home_phone "237264827652"
    country "US"
    association :club
    association :terms_of_membership
  end

end