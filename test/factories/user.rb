FactoryGirl.define do

  factory :user do
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla#{n}@test.no" }
  end

  factory :confirmed_admin_user, class: User do
    username "test"
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "carla#{n}@test.no" }
    confirmed_at Date.today-1.month
  end

end