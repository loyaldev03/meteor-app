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
    sequence(:username) {|n| "Admin#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "admin#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["admin"]
  end

  factory :confirmed_representative_agent, class: Agent do
    sequence(:username) {|n| "Representative#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "representative#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["representative"]
  end

  factory :confirmed_supervisor_agent, class: Agent do
    sequence(:username) {|n| "Supervisor#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "supervisor#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["supervisor"]
  end

  factory :confirmed_api_agent, class: Agent do
    sequence(:username) {|n| "api#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "api#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles ["api"]
  end

end
