FactoryGirl.define do

	factory :operation do
		description 'Operation'
		operation_date { DateTime.now }
	end

	factory :operation_profile, class: Operation do
		description 'Blacklisted member. Reason: Too much spam'
		operation_date { DateTime.now }
	end

	factory :operation_communication, class: Operation do
		description 'Communication sent'
		operation_date { DateTime.now }
	end

	factory :operation_other, class: Operation do
		description 'Member updated successfully'
		operation_date { DateTime.now }
	end
end