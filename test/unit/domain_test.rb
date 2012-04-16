require 'test_helper'

class DomainTest < ActiveSupport::TestCase

	test "Domain should not be created without a partner_id" do
		domain = FactoryGirl.build(:domain)
		assert !domain.save, "Domain was saved without a partner_id"
	end

	test "Domain should not be create without a club" do
		domain = FactoryGirl.build(:domain)
		domain.club_id = nil
		assert !domain.save, "Domain was saved without a club_id"
	end
end
