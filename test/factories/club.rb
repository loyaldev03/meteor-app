FactoryGirl.define do
  factory :club do
    sequence(:name) {|n| "club#{n}" }
    cs_phone_number "123 456 7891"
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    billing_enable true
    family_memberships_allowed false
    association :partner
  end

  factory :simple_club, class: Club do
    sequence(:name) {|n| "simple_club#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    association :partner
  end

  factory :simple_club_with_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
  end  

  factory :simple_club_with_litle_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_litle_gateway#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:litle_payment_gateway_configuration) }
  end  

  factory :simple_club_with_authorize_net_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_authorize_net_gateway#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:authorize_net_payment_gateway_configuration) }
  end  

  factory :simple_club_with_first_data_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_first_data_gateway#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:first_data_payment_gateway_configuration) }
  end  

  factory :simple_club_with_gateway_with_family, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_with_family#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    family_memberships_allowed true
    time_zone { TZInfo::Timezone.all.sample.name }
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
  end  


  factory :club_with_api, class: Club do
    sequence(:name) {|n| "club_with_api#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
  end

  factory :club_with_wordpress_api, class: Club do
    sequence(:name) {|n| "club_with_wordpress_api#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Wordpress::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
  end

  factory :club_with_gateway, class: Club do
    sequence(:name) {|n| "club_with_gateway#{n}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
  end  

  factory :simple_club_with_require_external_id, class: Club do
    sequence(:name) {|n| "simple_club_with_require_external_id#{n}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    requires_external_id true
    family_memberships_allowed false
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
  end
end