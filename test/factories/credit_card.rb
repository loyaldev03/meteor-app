FactoryGirl.define do

  factory :credit_card do
    active true
    expire_month { (Date.today + 1.month).month }
    expire_year { (Date.today + 1.year).year }
    number "4012301230123010"
  end

  factory :credit_card_master_card, class: CreditCard do
    active true
    expire_month { (Date.today + 1.month).month }
    expire_year { (Date.today + 1.year).year }
    number "5589548939080095"
  end

end