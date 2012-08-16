FactoryGirl.define do

  factory :agent do
    sequence(:username) {|n| "User#{n}" }
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla#{n}@test.no" }
  end

  factory :confirmed_agent, class: Agent do
    sequence(:username) {|n| "ConAgent#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "con_agent#{n}@test.no" }
    confirmed_at Date.today-1.month
  end

  factory :confirmed_admin_agent, class: Agent do
    sequence(:username) {|n| "ConAdmAgent#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "con_adm_agent#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["admin"]
  end



end
