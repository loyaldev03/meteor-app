FactoryGirl.define do

  factory :terms_of_membership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    needs_enrollment_approval false
    club_cash_amount 150
    association :club
  end

  factory :terms_of_membership_hold_card, class: TermsOfMembership do
    name "test Hold card 004"
    installment_amount 0.04 
    installment_type '1.month'
    needs_enrollment_approval false
    club_cash_amount 150
    association :club
  end

  factory :terms_of_membership_do_not_honor, class: TermsOfMembership do
    name "test do not honor 0045"
    installment_amount 0.05 
    installment_type '1.month'
    needs_enrollment_approval false
    club_cash_amount 150
    association :club
  end

  factory :terms_of_membership_insuf_funds, class: TermsOfMembership do
    name "test insuf funds"
    installment_amount 0.51 
    installment_type '1.month'
    needs_enrollment_approval false
    club_cash_amount 150
    association :club
  end

  factory :terms_of_membership_with_gateway, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    needs_enrollment_approval false
    club_cash_amount 150
    association :club, factory: :club_with_gateway
  end

  factory :terms_of_membership_with_gateway_needs_approval, class: TermsOfMembership do
    name "test"
    installment_amount 100
    installment_type '1.month'
    needs_enrollment_approval true
    club_cash_amount 150
    association :club, factory: :club_with_gateway
  end

end