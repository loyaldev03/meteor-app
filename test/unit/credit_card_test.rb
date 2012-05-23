require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
	
	test "Should not let activate a blacklisted credit card" do
	  credit_card_one = FactoryGirl.create(:credit_card)
      credit_card_two = FactoryGirl.create(:credit_card_master_card)
      credit_card_one.blacklisted = 1
      credit_card_one.active = 1
      assert !credit_card_one.save, "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
	end

end
