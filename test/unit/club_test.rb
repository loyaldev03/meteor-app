require 'test_helper'

class ClubTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "Should not save without name" do
  	club = FactoryGirl.build(:club)
  	club.name = nil
  	assert !club.save, "Club was saved without a name"
  end

  test "Should not save without partner_id" do
  	club = FactoryGirl.build(:club)
  	club.partner_id = nil
  	assert !club.save, "Club was saved without a partner_id"
  end


end
