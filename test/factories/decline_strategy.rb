FactoryGirl.define do

  factory :soft_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 102
    decline_type 'soft'
    credit_card_type 'all'
    installment_type "monthly"
    gateway 'mes'
    limit '1'
  end

  factory :hard_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 104
    decline_type 'hard'
    credit_card_type 'all'
    installment_type "monthly"
    gateway 'mes'
    limit '1'
  end

end
