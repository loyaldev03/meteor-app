FactoryGirl.define do
  factory :user_membership, class: Membership do
    status "none"
  end

  factory :user_with_api_membership, class: Membership do
    join_date { DateTime.now }
    status "none"
  end

  factory :user_with_cc_membership, class: Membership do
    join_date { DateTime.now }
  end

  factory :active_user_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :active_user_with_external_id_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :active_user_without_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'active'
  end

  factory :provisional_user_with_cc_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
  end

  factory :provisional_user_membership, class: Membership do
    join_date { DateTime.now }
    status 'provisional'
  end

  factory :applied_user_membership, class: Membership do
    join_date { DateTime.now }
    status 'applied'
  end

  factory :lapsed_user_membership, class: Membership do
    join_date { DateTime.now }
    status 'lapsed'
    cancel_date { Time.zone.now + 1.month }
  end

end