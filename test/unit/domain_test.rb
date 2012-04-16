require 'test_helper'

class DomainTest < ActiveSupport::TestCase

	test "Domain should not be created without a partner_id" do
		domain = FactoryGirl.build(:domain)
		assert !domain.save 
	end


end
