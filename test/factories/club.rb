FactoryGirl.define do
  factory :club do
    name { Faker::Name.name }
    description "My description"
    association :partner
  end

  factory :club_with_gateway, class: Club do
    name { Faker::Name.name }
    description "My description"
    association :partner
    after_create { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  
end