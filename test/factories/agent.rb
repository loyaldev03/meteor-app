FactoryGirl.define do

  factory :agent do
    sequence(:username) {|n| "User#{n}" }
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla#{n}@test.no" }
    authentication_token {Devise.friendly_token.first(8)} #TODO: I added this line because it looks like this value was set on record creation in prev devise gem. I don't see any issue of having users without tokens. So, I guess there is nothing to do here. Just to discuss my comment and delete it.
  end

  factory :confirmed_agent, class: Agent do
    sequence(:username) {|n| "ConAgent#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "con_agent#{n}@test.no" }
    confirmed_at Date.today-1.month
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_admin_agent, class: Agent do
    sequence(:username) {|n| "Admin#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "admin#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "admin"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_representative_agent, class: Agent do
    sequence(:username) {|n| "Representative#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "representative#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "representative"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_fulfillment_manager_agent, class: Agent do
    sequence(:username) {|n| "Fulfillment#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "fulfillment_manager#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "fulfillment_managment"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_supervisor_agent, class: Agent do
    sequence(:username) {|n| "Supervisor#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "supervisor#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "supervisor"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_api_agent, class: Agent do
    sequence(:username) {|n| "api#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "api#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "api"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_agency_agent, class: Agent do
    sequence(:username) {|n| "agency#{n}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "agency#{n}@test.no" }
    confirmed_at Date.today-1.month
    roles "agency"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :batch_agent, class: Agent do
    email "batch@xagax.com"
    username "batch@xagax.com"
    password  "batch@xagax.com"
    password_confirmation  "batch@xagax.com"
    authentication_token {Devise.friendly_token.first(8)}
  end
end