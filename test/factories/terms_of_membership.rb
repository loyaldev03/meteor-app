FactoryGirl.define do

  factory :terms_of_membership do
    association :club
    association :payment_gateway_configuration
  end

end