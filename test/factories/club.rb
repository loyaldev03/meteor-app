FactoryGirl.define do
  factory :club do
    name { Faker::Name.name }
    description "My description"
    association :partner
    payment_gateway_configurations {|ccs| [ccs.association(:payment_gateway_configuration)]}
  end
end