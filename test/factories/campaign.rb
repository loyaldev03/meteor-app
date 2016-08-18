FactoryGirl.define do

  factory :campaign do
    sequence(:name) {|n| "Campaign_#{Faker::Commerce.product_name}" }
    initial_date Time.zone.now
    finish_date Time.zone.now + 7.days    
    enrollment_price { Faker::Number.decimal(2) }
    campaign_type 0
    transport 0
    transport_campaign_id  {Faker::Lorem.characters(20)}   
    campaign_medium "display"
    campaign_medium_version "banner"
    marketing_code { Faker::Lorem.characters(10) }
    fulfillment_code { Faker::Lorem.characters(20) }

    factory :campaign_twitter do
        transport 2
    end

  end  
end