FactoryGirl.define do

  factory :prospect do
    sequence(:email) {|n| "prospect#{n}@test.no" }
    first_name { Faker::Name.first_name  }
    last_name { Faker::Name.last_name }
    address { Faker::Address.street_address  }
    city { Faker::Address.city }
    zip { Faker::Address.zip }
  end

end