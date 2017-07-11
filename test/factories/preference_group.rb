FactoryGirl.define do
  factory :preference_group do
    name {Faker::Lorem.characters(20)}
    code { Faker::Lorem.characters(10) }
    add_by_default false
  
    factory :preference_group_with_preferences do
      after_create do |preference_group| 
        FactoryGirl.create(:preference, preference_group_id: preference_group.id)
      end
      after_create do |preference_group| 
        FactoryGirl.create(:preference, preference_group_id: preference_group.id)
      end
    end
  end
end