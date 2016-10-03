FactoryGirl.define do
  
  factory :simple_domain, class: Domain do
    url { "http://#{Faker::Internet.domain_name}" }
    sequence(:data_rights) {|n| "data_rights_#{n}" }
    sequence(:description) {|n| "description_#{n}" }
    association :club
  end

  factory :domain do
    url { "http://#{Faker::Internet.domain_name}" }
    #association :partner, factory: :partner, strategy: :build
    #association :club
  end
end