FactoryGirl.define do
  factory :member_membership, class: Membership do
    join_date { DateTime.now }
    status "none"
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :member_with_api_membership, class: Membership do
    join_date { DateTime.now }
    status "none"
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :member_with_cc_membership, class: Membership do
    join_date { DateTime.now }
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :active_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :active_member_with_external_id_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :active_member_without_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :provisional_member_with_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :provisional_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :applied_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'applied'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :lapsed_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'lapsed'
    cancel_date { DateTime.now - 1.month }
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

end