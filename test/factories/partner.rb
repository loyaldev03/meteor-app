FactoryGirl.define do

  factory :partner do
    prefix { Faker::Internet.domain_word.upcase }
    name { Faker::Internet.domain_word }
    sequence(:description) {|n| "description_#{n}" }
  end

end