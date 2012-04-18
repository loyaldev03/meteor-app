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

	test "Domain shouldnt be destroyed is its the last one" do
		partner = FactoryGirl.create(:partner)
		first_domain = FactoryGirl.create(:domain, :partner_id => partner.id)
		second_domain = FactoryGirl.create(:domain, :partner_id => partner.id)
        
        first_domain.destroy
        assert !second_domain.destroy, "Domain was destroyed when it was the last one"     
	end

end
