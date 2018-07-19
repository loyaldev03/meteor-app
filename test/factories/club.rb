FactoryBot.define do
  factory :club do
    sequence(:name) {|n| "club_#{Faker::Lorem.characters(10)}" }
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    billing_enable true
    family_memberships_allowed false
    association :partner
    fulfillment_tracking_prefix 'T'
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end

  factory :simple_club, class: Club do
    sequence(:name) {|n| "simple_club_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    association :partner
    fulfillment_tracking_prefix 'T'
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end

  factory :simple_club_with_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_#{Faker::Lorem.characters(10)}" }
    member_landing_url "products.onmc.com"
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed true
    association :partner
    marketing_tool_client :action_mailer     
    header_image_url_file_name { Faker::Avatar.image("my-own-slug", "50x50", "jpg") }
    checkout_page_bonus_gift_box_content "<p>Included with your Merchandise is a Risk Free 30 of the Club.</p>"
    checkout_page_footer "OFFER AND BILLING DETAILS: Your Bonus Gift"
    checkout_url "http://test.host"
    thank_you_page_content "<h2>Thank you for your order!</h2>"
    duplicated_page_content "<h2>Duplicated Member</h2>"
    error_page_content "<h2>Error!</h2>
                        <p>There seems to be a problem with your payment information.</p>"
    result_page_footer "Privacy Policy"
    after(:create) do |club| 
      club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration)
      club.products << FactoryBot.create(:product)
    end
  end  

  factory :simple_club_with_litle_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_litle_gateway_#{Faker::Lorem.characters(10)}" }   
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    marketing_tool_client :action_mailer
    after(:create) do |club| 
      club.payment_gateway_configurations << FactoryBot.build(:litle_payment_gateway_configuration)
    end
    after(:create) do |club| 
      FactoryBot.create(:product, club_id: club.id)
    end
  end  

  factory :simple_club_with_authorize_net_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_authorize_net_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    association :partner
    fulfillment_tracking_prefix 'T'
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:authorize_net_payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_first_data_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_first_data_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:first_data_payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_stripe_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_stripe_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:stripe_payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_trust_commerce_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner

    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:trust_commerce_payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_payeezy_gateway, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner

    marketing_tool_client :action_mailer
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payeezy_payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }    
  end

  factory :simple_club_with_gateway_with_family, class: Club do
    sequence(:name) {|n| "simple_club_with_gateway_with_family_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    family_memberships_allowed true
    time_zone { TZInfo::Timezone.all.sample.name }
    fulfillment_tracking_prefix 'T'
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration) }
    association :partner
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :club_with_api, class: Club do
    sequence(:name) {|n| "club_with_api_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Drupal::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end

  factory :club_with_wordpress_api, class: Club do
    sequence(:name) {|n| "club_with_wordpress_api_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_type 'Wordpress::Member'
    association :api_domain, factory: :domain
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end

  factory :club_with_gateway, class: Club do
    sequence(:name) {|n| "club_with_gateway_#{Faker::Lorem.characters(10)}" }
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end  

  factory :simple_club_with_require_external_id, class: Club do
    sequence(:name) {|n| "simple_club_with_require_external_id_#{Faker::Lorem.characters(10)}" }
    description "My description"
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    billing_enable true
    time_zone { TZInfo::Timezone.all.sample.name }
    api_username { Faker::Internet.user_name }
    api_password { Faker::Internet.user_name }
    requires_external_id true
    family_memberships_allowed false
    fulfillment_tracking_prefix 'T'
    association :partner
    after(:create) { |club| club.payment_gateway_configurations << FactoryBot.build(:payment_gateway_configuration) }
    after(:create) { |club| FactoryBot.create(:product, club_id: club.id) }
  end

  factory :club_without_product, class: Club do
    sequence(:name) {|n| "club_#{Faker::Lorem.characters(10)}" }
    cs_phone_number "123 456 7891"
    cs_email 'customer_service@example.com'
    time_zone { TZInfo::Timezone.all.sample.name }
    description "My description"
    billing_enable true
    family_memberships_allowed false
    association :partner
    fulfillment_tracking_prefix 'T'
  end
end