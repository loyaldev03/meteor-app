FactoryBot.define do

  factory :soft_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 302 #Credit Floor - Insufficient funds
    decline_type 'soft'
    credit_card_type 'all'
    gateway 'payeezy'
    max_retries '4'
  end

  factory :without_grace_period_decline_strategy_monthly, class: DeclineStrategy do
    days 0
    response_code Settings.error_codes.credit_card_blank_without_grace
    decline_type 'hard'
    credit_card_type 'all'
    gateway 'payeezy'
    max_retries '1'
  end

  factory :without_grace_period_decline_strategy_yearly, class: DeclineStrategy do
    days 0
    response_code Settings.error_codes.credit_card_blank_without_grace
    decline_type 'hard'
    credit_card_type 'all'
    gateway 'payeezy'
    max_retries '1'
  end

  factory :hard_decline_strategy, class: DeclineStrategy do
    days 2
    response_code 502 #Lost/Stolen - Card reported as lost/stolen
    decline_type 'hard'
    credit_card_type 'all'
    gateway 'payeezy'
    max_retries '1'
  end

  factory :hard_decline_strategy_for_billing, class: DeclineStrategy do
    notes "Credit card is blank and grace period is disabled"
    days 0
    response_code 9997
    decline_type 'hard'
    credit_card_type 'all'
    gateway 'payeezy'
    max_retries '0'
  end
end
