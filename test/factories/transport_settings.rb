FactoryGirl.define do

  factory :transport_settings_facebook do
    transport { TransportSetting.transports['facebook'] } 
    settings '{"client_id":"994106","client_secret":"f54adccaae4e24","access_token":"hYNzoPqguM6qHWuQp5hM6ZChVSZAoZCcgixXbIQZDZD"}'    
  end

  factory :transport_settings_mailchimp do    
    transport { TransportSetting.transports['mailchimp'] }     
    settings '{"api_key":"a76496027e5e-us8"}'        
  end
end