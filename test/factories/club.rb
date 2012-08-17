FactoryGirl.define do
  factory :club do
    name { Faker::Name.name }
    description "My description"
  end

  factory :simple_club, class: Club do
    name { Faker::Name.name }
    description "My description"
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
  end

  factory :club_with_api, class: Club do
    name { Faker::Name.name }
    description "My description"
    association :partner
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
  end

  factory :club_with_gateway, class: Club do
    name { Faker::Name.name }
    description "My description"
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  
end