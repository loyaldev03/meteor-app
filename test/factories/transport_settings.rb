FactoryBot.define do
  factory :transport_settings_facebook, class: TransportSetting do
    transport { TransportSetting.transports['facebook'] }
    client_id { Faker::Number.number(8) }
    client_secret { Faker::Lorem.characters(20) }
    access_token { Faker::Lorem.characters(100) }
  end

  factory :transport_settings_mailchimp, class: TransportSetting do
    transport { TransportSetting.transports['mailchimp'] }
    api_key { Faker::Lorem.characters(40)}
  end

  factory :transport_settings_google_analytics, class: TransportSetting do
    transport { TransportSetting.transports['google_analytics'] }
    tracking_id { Faker::Lorem.characters(40)}
  end

  factory :transport_settings_google_tag_manager, class: TransportSetting do
    transport { TransportSetting.transports['google_tag_manager'] }
    container_id { Faker::Lorem.characters(40)}
  end

  factory :transport_settings_store, class: TransportSetting do
    transport { TransportSetting.transports['store_spree'] }
    url { 'https://dailydeals.onmc.com' }
    api_token { 'b3988e7a0a2513d2cbf5f015c71e34584f59f9f86e70ffd1' }
  end
end
