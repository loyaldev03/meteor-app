Factory.define :user do |u|
  u.password "secret"
  u.password_confirmation {|u| u.password}
  u.sequence(:email) {|n| "carla#{n}@test.no" }
end
