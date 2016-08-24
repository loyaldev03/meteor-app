FactoryGirl.define do

  factory :transport_settings_facebook, class: TransportSetting do
    transport { TransportSetting.transports['facebook'] } 
    client_id { Faker::Number.decimal(6) }
    client_secret {Faker::Lorem.characters(20)}  
    access_token {Faker::Lorem.characters(60)} 
  end

  factory :transport_settings_mailchimp, class: TransportSetting do    
    transport { TransportSetting.transports['mailchimp'] } 
    api_key {Faker::Lorem.characters(40)}      
  end
end