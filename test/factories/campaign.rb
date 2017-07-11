FactoryGirl.define do
  factory :campaign do
    sequence(:name) {|n| "Campaign_#{Faker::Commerce.product_name}" }
    landing_name "flag"
    initial_date Time.zone.today
    finish_date Time.zone.tomorrow + 7.days    
    enrollment_price { Faker::Number.decimal(2) }
    campaign_type { Campaign.campaign_types['sloop'] } 
    transport { Campaign.transports['facebook'] }    
    transport_campaign_id {Faker::Lorem.characters(20)}   
    utm_medium "display"
    utm_content "banner"
    audience { Faker::Lorem.characters(10) }
    campaign_code { Faker::Lorem.characters(20) }
    delivery_date "3 - 5 weeks from date ordered"
    after_create { |campaign| campaign.update_attribute(:slug, nil) ; campaign.save }

    factory :campaign_twitter do
      transport { Campaign.transports['twitter'] }
    end

    factory :campaign_mailchimp do
      transport { Campaign.transports['mailchimp'] }
      utm_medium "email"
      utm_content "email_medium"
    end

    factory :campaign_newsletter do
      campaign_type { Campaign.campaign_types['newsletter'] }
    end

    factory :campaign_store_promotion do
      campaign_type { Campaign.campaign_types['store_promotion'] }
    end
  end  
end