FactoryGirl.define do

  factory :domain do
    url "http://FactoryGirl.com.ar"
    association :partner, factory: :partner, strategy: :build
    association :club
  end
  factory :domain_with_different_url, class: Domain do
    url "http://second_domain.com.ar"
    #association :partner
  end
end