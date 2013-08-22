require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
	
	test "Should not let activate a blacklisted credit card" do
	  credit_card_one = FactoryGirl.create(:credit_card)
	  credit_card_two = FactoryGirl.create(:credit_card_master_card)
    assert !(credit_card_one.blacklist && credit_card_one.activate), "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
	end

	test "CC dates validation within club with negative offset" do 
	  credit_card = FactoryGirl.create(:credit_card)
    Time.zone = "International Date Line West"
	  # # testing internal logic
	  offset = credit_card.get_offset_related
	  date = Time.new(Time.zone.now.year+10, Time.zone.now.month, nil, nil, nil, nil, offset)
	  assert_equal date.gmt_offset/3600, Time.zone.now.gmt_offset/3600
	end

	test "CC dates validation within club with positive offset" do 
	  credit_card = FactoryGirl.create(:credit_card)
    Time.zone = "Pacific/Kiritimati"
	  # # testing internal logic
	  offset = credit_card.get_offset_related
	  date = Time.new(Time.zone.now.year+10, Time.zone.now.month, nil, nil, nil, nil, offset)
	  assert_equal date.gmt_offset/3600, Time.zone.now.gmt_offset/3600
	end

	test "CC dates validation within club with offset = +00:00" do 
	  credit_card = FactoryGirl.create(:credit_card)
		Time.zone = "UTC"
	  # # testing internal logic
	  offset = credit_card.get_offset_related
	  date = Time.new(Time.zone.now.year+10, Time.zone.now.month, nil, nil, nil, nil, offset)
	  assert_equal date.gmt_offset/3600, Time.zone.now.utc.gmt_offset/3600
	end
end
