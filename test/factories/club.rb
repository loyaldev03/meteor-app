FactoryGirl.define do
  factory :club do
    name Faker::Name.name
    description "My description"
    association :partner
  end
end