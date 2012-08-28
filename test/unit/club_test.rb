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
  
  test "After creating a club, it should add a product to that club" do
    assert_difference('Product.count') do
      @club.save
    end
  end

end
