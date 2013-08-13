FactoryGirl.define do

  factory :terms_of_membership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_hold_card, class: TermsOfMembership do
    name "test Hold card 004"
    installment_amount 0.04 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_do_not_honor, class: TermsOfMembership do
    name "test do not honor 0045"
    installment_amount 0.05 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_insuf_funds, class: TermsOfMembership do
    name "test insuf funds"
    installment_amount 0.51 
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club
  end

  factory :terms_of_membership_with_gateway, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :wordpress_terms_of_membership_with_gateway, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :club_with_wordpress_api
  end

  factory :terms_of_membership_with_gateway_with_family, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway_with_family
  end

  factory :terms_of_membership_with_gateway_and_external_id, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :simple_club_with_require_external_id
  end

  factory :terms_of_membership_with_gateway_and_api, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :club_with_api
  end


  factory :terms_of_membership_with_gateway_yearly, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 12
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :club_with_gateway
  end

  factory :terms_of_membership_with_gateway_needs_approval, class: TermsOfMembership do
    name "test-approval"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval true
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_with_gateway_without_club_cash, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 0
    provisional_days 30
    # association :club, factory: :club_with_gateway
  end  

  factory :life_time_terms_of_membership, class: TermsOfMembership do
    name "test-lifetime"
    installment_amount 100
    installment_period 365000 # installment_type '1000.years'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_monthly_without_provisional_day_and_amount, class: TermsOfMembership do
    name "test"
    installment_amount 0
    installment_period 30 # installment_type '1.month'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_yearly_without_provisional_day_and_amount, class: TermsOfMembership do
    name "test"
    installment_amount 0
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_for_downgrade, class: TermsOfMembership do
    name "downgrade_free_membership"
    installment_amount 0
    installment_period 365 # installment_type '1.year'
    initial_fee 0
    trial_period_amount 0
    is_payment_expected false
    suscription_limits 0
    if_cannot_bill 'cancel'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 0
    provisional_days 0
    # association :club, factory: :simple_club_with_gateway
  end
end