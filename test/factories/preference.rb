FactoryBot.define do
  factory :preference do
    name {Faker::Lorem.characters(20)}
  end
end 