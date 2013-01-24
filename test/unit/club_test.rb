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
  
  test "After creating a club, it should add two product to that club" do
    assert_difference('Product.count') do
      @club.save
    end
  end

  test "After creating a club, it should add ten disposition types to that club" do
    assert_difference('Enumeration.count',13) do  #3 are Member's group type and 10 from disposition types.
      @club.save
    end
  end

end
