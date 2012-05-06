FactoryGirl.define do

  factory :credit_card do
    active true
    expire_month 12
    expire_year 2013
    number "4012301230123010"
    association :member
  end

  factory :credit_card_master_card, class: CreditCard do
    active true
    expire_month 12
    expire_year 2013
    number "5589548939080095 "
  end

end