FactoryGirl.define do

  factory :user_membership, class: Membership do
    join_date { DateTime.now }
    product_sku Settings.others_product
    status "provisional"

    factory :provisional_user_membership do
      status 'provisional'
    end

    factory :membership_without_enrollment_amount do
      enrollment_amount 0.0
    end

    factory :user_with_api_membership do
      status 'provisional'
      join_date { DateTime.now }
    end

    factory :user_with_cc_membership do
      status 'provisional'
      join_date { DateTime.now }
    end

    factory :active_user_membership do
      status 'active'
      join_date { DateTime.now }
    end

    factory :active_user_with_external_id_membership do
      status 'active'
      join_date { DateTime.now }
    end

    factory :active_user_without_cc_membership do
      join_date { DateTime.now }
      status 'active'
    end

    factory :provisional_user_with_cc_membership do
      status 'provisional'
      join_date { DateTime.now }
    end

    factory :applied_user_membership do
      status 'applied'
      join_date { DateTime.now }
    end

    factory :lapsed_user_membership do
      status 'lapsed'
      join_date { DateTime.now }
      cancel_date { Time.zone.now + 1.month }
    end

    factory :membership_with_enrollment_info do
      enrollment_amount 0.5
      ip_address '190.224.250.164'
      utm_medium 'xyz123456'
      user_agent 'Mozilla\/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit\/536.11 (KHTML, like Gecko) Chrome\/20.0.1132.47 Safari\/536.11'
      utm_campaign 'super channel'
    end

    factory :membership_with_enrollment_info_without_enrollment_amount do
      enrollment_amount 0.0
    end
  end

end