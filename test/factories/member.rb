FactoryGirl.define do

  factory :member do
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