FactoryGirl.define do

  factory :agent do
    sequence(:username) {|n| "User#{n}" }
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla#{n}@test.no" }
  end

  factory :confirmed_admin_agent, class: Agent do
    sequence(:username) {|n| "User#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "carla#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["admin"]
  end

end
