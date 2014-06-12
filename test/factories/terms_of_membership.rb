FactoryGirl.define do

  factory :terms_of_membership do
    sequence(:name) {|n| "test_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_hold_card, class: TermsOfMembership do
    sequence(:name) {|n| "test Hold card 004_#{n}" }
    installment_amount 0.04 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_do_not_honor, class: TermsOfMembership do
    sequence(:name) {|n| "test do not honor 0045_#{n}" }
    installment_amount 0.05 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_insuf_funds, class: TermsOfMembership do
    sequence(:name) {|n| "test insuf funds_#{n}" }
    installment_amount 0.51 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_with_gateway, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :wordpress_terms_of_membership_with_gateway, class: TermsOfMembership do
    sequence(:name) {|n| "test wordpress with gateway_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :club_with_wordpress_api
  end

  factory :terms_of_membership_with_gateway_with_family, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway and family_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway_with_family
  end

  factory :terms_of_membership_with_gateway_and_external_id, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway and external id#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_require_external_id
  end

  factory :terms_of_membership_with_gateway_and_api, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway and api#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :club_with_api
  end


  factory :terms_of_membership_with_gateway_yearly, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway yearly#{n}" }
    installment_amount 100
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :club_with_gateway
  end

  factory :terms_of_membership_with_gateway_needs_approval, class: TermsOfMembership do
    sequence(:name) {|n| "test-approval_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval true
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_with_gateway_without_club_cash, class: TermsOfMembership do
    sequence(:name) {|n| "test without club cash_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 0
    club_cash_installment_amount 0
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :club_with_gateway
  end  

  factory :life_time_terms_of_membership, class: TermsOfMembership do
    sequence(:name) {|n| "test-lifetime_#{n}" }
    installment_amount 100
    installment_period 365000 # installment_type '1000.years'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_monthly_without_provisional_day_and_amount, class: TermsOfMembership do
    sequence(:name) {|n| "test monthly without provisional days and amount_#{n}" }
    installment_amount 0
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_yearly_without_provisional_day_and_amount, class: TermsOfMembership do
    sequence(:name) {|n| "test yearly without provisional day and amount_#{n}" }
    installment_amount 0
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_for_downgrade, class: TermsOfMembership do
    sequence(:name) {|n| "downgrade_free_membership_#{n}" }
    installment_amount 0
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval false
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_with_gateway_and_approval_required, class: TermsOfMembership do
    sequence(:name) {|n| "test with gateway_#{n}" }
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected 1
    subscription_limits 0
    if_cannot_bill 'cancel'
    needs_enrollment_approval true
    initial_club_cash_amount 150
    club_cash_installment_amount 100
    skip_first_club_cash 0
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end












end