TEST_COHORT = "%Y-%m-super channel-xyz123456-1.month"
FactoryGirl.define do
  factory :membership do
    join_date { DateTime.now }
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :active_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :provisional_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :applied_membership, class: Membership do
    join_date { DateTime.now }
    status 'applied'
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

  factory :lapsed_membership, class: Membership do
    join_date { DateTime.now }
    status 'lapsed'
    cancel_date { DateTime.now - 1.month }
    cohort { Time.zone.now.strftime TEST_COHORT }
  end

end