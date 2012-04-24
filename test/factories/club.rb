FactoryGirl.define do
  factory :club do
    name "My Club"
    description "My description"
    association :partner
  end
end