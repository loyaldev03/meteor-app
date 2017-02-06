FactoryGirl.define do
  factory :preference_group do
    name {Faker::Lorem.characters(20)}
    code { Faker::Lorem.characters(10) }
    add_by_default false
  
    factory :preference_group_with_preferences do
      after(:create) { |preference_group| FactoryGirl.create(:preference, preference_group_id: preference_group.id) }
      after(:create) { |preference_group| FactoryGirl.create(:preference, preference_group_id: preference_group.id) }
    end
  end
end