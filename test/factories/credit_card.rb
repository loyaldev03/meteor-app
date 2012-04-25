FactoryGirl.define do

  factory :credit_card do
    active true
    expire_month 12
    expire_year 2013
    number "000000000000000"
    association :member
  end

end