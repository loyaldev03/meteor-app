FactoryGirl.define do
  factory :domain do
    url { "http://#{Faker::Internet.domain_name}" }
    association :partner, factory: :partner, strategy: :build
    association :club
  end
end