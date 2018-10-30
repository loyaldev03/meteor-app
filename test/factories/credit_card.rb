FactoryBot.define do

  factory :credit_card do
    active true
    expire_month { (Date.today + 3.month).month }
    expire_year { (Date.today + 2.year).year }
    number "4000060001234562"
    token "8748333042191111"
    gateway "payeezy"
  end

  factory :credit_card_master_card, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "5199701234567892"
    token "9729852103506619"
    gateway "payeezy"
  end

  factory :blank_credit_card, class: CreditCard do
    active true
    expire_month { (Date.today).month }
    expire_year { (Date.today).year }
    number "0000000000"
    token "a"
    gateway "payeezy"
  end

  factory :credit_card_american_express, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "340000000000009"
    token "032315636746108"
    gateway "payeezy"
  end

  factory :credit_card_american_express_litle, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "340504323632976"
    token '1111222233334444' # litle always use the same token on dev site
    gateway "little"
  end

  factory :credit_card_american_express_authorize_net, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "370000000000002" # credit card number is provided by Auth.Net
    gateway "authorize_net"
  end

  factory :credit_card_visa_first_data, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "4111111111111111" # VISA credit card number is provided by FirstData
    gateway "first_data"
  end

  factory :credit_card_visa_stripe, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "4242424242424242" # VISA credit card number is provided by Stripe
    gateway "stripe"
  end

  factory :credit_card_visa_payeezy, class: CreditCard do
    active true
    expire_month { (Date.today + 2.month).month }
    expire_year { (Date.today + 2.year).year }
    number "4111111111111111" # VISA credit card number is provided by Payeezy
    token "9782465740991323"
    gateway "payeezy"
  end
end