FactoryGirl.define do
  factory :club do
    sequence(:name) {|n| "club_#{Faker::Lorem.characters(10)}" }
    cs_phone_number "123 456 7891"
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    billing_enable true
    family_memberships_allowed false
    association :partner
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end

  factory :simple_club, class: Club do
    sequence(:name) {|n| "simple_club_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end

  factory :simple_club_with_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_#{Faker::Lorem.characters(10)}" }
    member_landing_url "products.onmc.com"
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_litle_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_litle_gateway_#{Faker::Lorem.characters(10)}" }   
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:litle_payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_authorize_net_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_authorize_net_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:authorize_net_payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_first_data_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_first_data_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:first_data_payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_stripe_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_stripe_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:stripe_payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_trust_commerce_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner

    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:trust_commerce_payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_gateway_with_family, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_with_family_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    family_memberships_allowed true
    time_zone { TZInfo::Timezone.all.sample.name }
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    association :partner
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :club_with_api, class: Club do
    sequence(:name) {|n| "club_with_api_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end

  factory :club_with_wordpress_api, class: Club do
    sequence(:name) {|n| "club_with_wordpress_api_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Wordpress::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end

  factory :club_with_gateway, class: Club do
    sequence(:name) {|n| "club_with_gateway_#{Faker::Lorem.characters(10)}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_require_external_id, class: Club do
    sequence(:name) {|n| "simple_club_with_require_external_id_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    requires_external_id true
    family_memberships_allowed false
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryGirl.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryGirl.create(:product, club_id: club.id) }
  end
end