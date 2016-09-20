FactoryGirl.define do

  factory :campaign_day do
    date Time.zone.now
    spent Faker::Number.number(5)
    reached Faker::Number.number(7)
    converted Faker::Number.number(5)

    factory :missing_campaign_day do
      date Time.zone.now
      spent nil
      reached nil
      converted nil
    end
  end  
end
