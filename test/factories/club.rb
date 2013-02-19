FactoryGirl.define do
  factory :club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    cs_phone_number "123 456 7891"
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    billing_enable true
    association :partner
    family_memberships_allowed false
  end

  factory :simple_club, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
  end

  factory :simple_club_with_gateway, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    family_memberships_allowed false
  end  

  factory :simple_club_with_gateway_with_family, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    family_memberships_allowed true
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  


  factory :club_with_api, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end

  factory :club_with_wordpress_api, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    association :partner
    api_type 'Wordpress::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end

  factory :club_with_gateway, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    association :partner
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  

  factory :simple_club_with_require_external_id, class: Club do
    sequence(:name) {|n| "#{Faker::Name.name}#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    association :partner
    requires_external_id true
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end
end