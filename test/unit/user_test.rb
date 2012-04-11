require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "the truth" do 
    assert true
  end

  test "Shouldnt be two users with samen name" do
  	  user = FactoryGirl.build(:user)
     user.username = "user"
     user.save
  	  assert !user.new_record?, "There are two users with the same name" 
  end




end
