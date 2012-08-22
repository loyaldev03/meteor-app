require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
	
	test "Should not let activate a blacklisted credit card" do
	  credit_card_one = FactoryGirl.create(:credit_card)
    credit_card_two = FactoryGirl.create(:credit_card_master_card)
    assert !(credit_card_one.blacklist && credit_card_one.activate), "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
	end

end
