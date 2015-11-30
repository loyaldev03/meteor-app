FactoryGirl.define do

  factory :agent do
    sequence(:username) {|n| "User_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation {password}
    sequence(:email) {|n| "carla_#{Faker::Lorem.characters(4)}@test.no" }
    authentication_token {Devise.friendly_token.first(8)} #TODO: I added this line because it looks like this value was set on record creation in prev devise gem. I don't see any issue of having users without tokens. So, I guess there is nothing to do here. Just to discuss my comment and delete it.
  end

  factory :confirmed_agent, class: Agent do
    sequence(:username) {|n| "ConAgent_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "con_agent_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_admin_agent, class: Agent do
    sequence(:username) {|n| "Admin_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "admin_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    roles "admin"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_representative_agent, class: Agent do
    sequence(:username) {|n| "Representative_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "representative_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    roles "representative"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_fulfillment_manager_agent, class: Agent do
    sequence(:username) {|n| "Fulfillment_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "fulfillment_manager_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    roles "fulfillment_managment"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_supervisor_agent, class: Agent do
    sequence(:username) {|n| "Supervisor_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "supervisor_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    roles "supervisor"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_api_agent, class: Agent do
    sequence(:username) {|n| "api_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "api_#{Faker::Lorem.characters(4)}@test.no" }
    confirmed_at Date.today-1.month
    roles "api"
    authentication_token {Devise.friendly_token.first(8)}
  end

  factory :confirmed_agency_agent, class: Agent do
    sequence(:username) {|n| "agency_#{Faker::Lorem.characters(4)}" }
    password "secret"
    password_confirmation { password }
    sequence(:email) {|n| "agency_#{Faker::Lorem.characters(4)}@test.no" }
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