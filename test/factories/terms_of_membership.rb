FactoryGirl.define do

  factory :terms_of_membership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club
  end

  factory :terms_of_membership_hold_card, class: TermsOfMembership do
    name "test Hold card 004"
    installment_amount 0.04 
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club
  end

  factory :terms_of_membership_do_not_honor, class: TermsOfMembership do
    name "test do not honor 0045"
    installment_amount 0.05 
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club
  end

  factory :terms_of_membership_insuf_funds, class: TermsOfMembership do
    name "test insuf funds"
    installment_amount 0.51 
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club
  end

  factory :terms_of_membership_with_gateway, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_with_gateway_with_family, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :simple_club_with_gateway_with_family
  end

  factory :terms_of_membership_with_gateway_and_external_id, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :simple_club_with_require_external_id
  end

  factory :terms_of_membership_with_gateway_and_api, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :club_with_api
  end


  factory :terms_of_membership_with_gateway_yearly, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.year'
    quota 12
    needs_enrollment_approval false
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :club_with_gateway
  end

  factory :terms_of_membership_with_gateway_needs_approval, class: TermsOfMembership do
    name "test-approval"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval true
    club_cash_amount 150
    provisional_days 30
    association :club, factory: :simple_club_with_gateway
  end

  factory :terms_of_membership_with_gateway_without_club_cash, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    quota 1
    needs_enrollment_approval false
    club_cash_amount 0
    provisional_days 30
    association :club, factory: :club_with_gateway
  end  
end