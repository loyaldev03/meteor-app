FactoryGirl.define do

  factory :user do
    ip_address '127.0.0.1'
    association :domain
  end
  
end