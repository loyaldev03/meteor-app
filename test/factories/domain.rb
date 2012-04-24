FactoryGirl.define do

  factory :domain do
    url "http://FactoryGirl.com.ar"
    association :partner
    association :club
  end
  factory :second_domain, class: Domain do
    url "http://second_domain.com.ar"
    #association :partner
  end
end