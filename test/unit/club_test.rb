require 'test_helper'

class ClubTest < ActiveSupport::TestCase

  setup do
    stubs_solr_index
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
    assert_difference('Enumeration.count',17) do  #4 are Member's group type and 13 from disposition types.
      @club.save
    end
  end

end
