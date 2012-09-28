FactoryGirl.define do
  factory :club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    association :partner
  end

  factory :simple_club, class: Club do
    sequence(:name) {|n| "club#{n}" }
    description "My description"
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
  end

  factory :simple_club_with_gateway, class: Club do
    sequence(:name) {|n| "club#{n}" }
    description "My description"
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  

  factory :club_with_api, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
  end

  factory :club_with_gateway, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  

  factory :simple_club_with_require_external_id, class: Club do
    sequence(:name) {|n| "club_with_external_id#{n}" }
    description "My description"
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    requires_external_id true
  end
end