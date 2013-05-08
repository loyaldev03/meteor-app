FactoryGirl.define do

  factory :credit_card do
    active true
    expire_month { (Date.today + 1.month).month }
    expire_year { (Date.today + 1.year).year }
    number "4012301230123010"
    token "c25ccfecae10384698a44360444dead8"
  end

  factory :credit_card_master_card, class: CreditCard do
    active true
    expire_month { (Date.today + 1.month).month }
    expire_year { (Date.today + 1.year).year }
    number "5589548939080095"
    token "c25ccfecae10384698a44360444dead7"
  end

  factory :credit_card_american_express, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "340504323632976"
    token "c25ccfecae10384698a44360444dead6"
  end

  factory :credit_card_american_express_litle, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "340504323632976"
    token '1111222233334444' # litle always use the same token on dev site
  end

  factory :credit_card_american_express_authorize_net, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "370000000000002" # credit card number is provided by Auth.Net
  end

end