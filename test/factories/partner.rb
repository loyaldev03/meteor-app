FactoryBot.define do

  factory :partner do
    prefix { Faker::Internet.domain_word.upcase+Faker::Internet.domain_word.upcase }
    name { Faker::Internet.domain_word+Faker::Internet.domain_word }
    sequence(:description) {|n| "description_#{n}" }
 		contract_uri { "http://#{Faker::Internet.domain_name}" }
		website_url { "http://#{Faker::Internet.domain_name}" }
  end

end