FactoryGirl.define do
  factory :member_membership, class: Membership do
    status "none"
  end

  factory :member_with_api_membership, class: Membership do
    join_date { DateTime.now }
    status "none"
  end

  factory :member_with_cc_membership, class: Membership do
    join_date { DateTime.now }
  end

  factory :active_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :active_member_with_external_id_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :active_member_without_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :provisional_member_with_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
  end

  factory :provisional_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
  end

  factory :applied_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'applied'
  end

  factory :lapsed_member_membership, class: Membership do
    join_date { DateTime.now }
    status 'lapsed'
    cancel_date { Time.zone.now + 1.month }
  end

end