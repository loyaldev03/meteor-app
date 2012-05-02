FactoryGirl.define do

  factory :terms_of_membership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    association :club
  end

end