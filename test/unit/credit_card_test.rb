require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
	setup do
    stubs_solr_index
  end

	test "Should not let activate a blacklisted credit card" do
	  credit_card_one = FactoryGirl.create(:credit_card)
	  credit_card_two = FactoryGirl.create(:credit_card_master_card)
    assert !(credit_card_one.blacklist && credit_card_one.activate), "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
	end

  
  
  def check_offset 
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    member = create_active_member(terms_of_membership, :provisional_member_with_cc)
    credit_card = member.active_credit_card
    # # testing internal logic
    assert_equal Time.now.in_time_zone(@club.time_zone).formatted_offset, credit_card.member.get_offset_related
  end
  
	test "CC dates validation within club with negative offset" do
		@club = FactoryGirl.create(:simple_club_with_gateway, :time_zone => "International Date Line West") 
    check_offset
  end

	test "CC dates validation within club with positive offset" do 
    @club = FactoryGirl.create(:simple_club_with_gateway, :time_zone => "Pacific/Kiritimati") 
    check_offset
	end

	test "CC dates validation within club with offset = +00:00" do 
    @club = FactoryGirl.create(:simple_club_with_gateway, :time_zone => "UTC") 
    check_offset
  end
end
