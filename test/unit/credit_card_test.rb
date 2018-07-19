require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
	test "Should not let activate a blacklisted credit card" do
	  credit_card_one = FactoryBot.create(:credit_card)
	  credit_card_two = FactoryBot.create(:credit_card_master_card)
    assert !(credit_card_one.blacklist && credit_card_one.activate), "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
	end

  
  
  def check_offset 
    terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    user = create_active_user(terms_of_membership, :provisional_user_with_cc)
    credit_card = user.active_credit_card
    # # testing internal logic
    assert_equal Time.now.in_time_zone(@club.time_zone).formatted_offset, credit_card.user.get_offset_related
  end
  
	test "CC dates validation within club with negative offset" do
		@club = FactoryBot.create(:simple_club_with_gateway, :time_zone => "International Date Line West") 
    check_offset
  end

	test "CC dates validation within club with positive offset" do 
    @club = FactoryBot.create(:simple_club_with_gateway, :time_zone => "Pacific/Kiritimati") 
    check_offset
	end

	test "CC dates validation within club with offset = +00:00" do 
    @club = FactoryBot.create(:simple_club_with_gateway, :time_zone => "UTC") 
    check_offset
  end
end
