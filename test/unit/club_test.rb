require 'test_helper'

class ClubTest < ActiveSupport::TestCase

  setup do
    @club = FactoryGirl.build(:club)
  end

  test "Should not save without name" do
  	@club.name = nil
  	assert !@club.save, "Club was saved without a name"
  end

  test "Should not save without partner_id" do
  	@club.partner_id = nil
  	assert !@club.save, "Club was saved without a partner_id"
  end
  
  test "After creating a club, it should addtwo product to that club" do
    assert_difference('Product.count',2) do
      @club.save
    end
  end

  test "Club should not be billed if billing_enable is set as false" do
    @club.billing_enable = false
    @club.save
    @member = FactoryGirl.create(:active_member, :club_id => @club.id, :email=> "testing_billing@gmail.com")
    assert_difference('Operation.count', 0) do
      assert_difference('Transaction.count', 0) do
        @member.bill_membership
      end
    end
  end
end
