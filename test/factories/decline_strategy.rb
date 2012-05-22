FactoryGirl.define do

  factory :soft_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 102
    decline_type 'soft'
    credit_card_type 'all'
    installment_type "1.month"
    gateway 'mes'
    limit '4'
  end

  factory :grace_period_decline_strategy, class: DeclineStrategy do
    days 2
    response_code Settings.error_codes.credit_card_blank_with_grace
    decline_type 'soft'
    credit_card_type 'all'
    installment_type "1.month"
    gateway 'mes'
    limit '1'
  end

  factory :hard_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 104
    decline_type 'hard'
    credit_card_type 'all'
    installment_type "1.month"
    gateway 'mes'
    limit '1'
  end

end
