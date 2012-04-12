# Factory.define :user do |u|
#   u.username "seba"
#   u.password "secret"
#   u.password_confirmation {|u| u.password}
#   u.sequence(:email) {|n| "carla#{n}@test.no" }
# end
# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do

  factory :user do
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla#{n}@test.no" }
  end

  factory :admin do
    username "test"
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "carla#{n}@test.no" }
  end

end