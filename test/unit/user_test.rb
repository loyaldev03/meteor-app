require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "Shouldnt be two users with samen name" do
    first = FactoryGirl.create(:user, :username => 'billy')
    assert first.valid?
    second = FactoryGirl.build(:user, :username => 'billy')
    second.valid?
    assert_not_nil second.errors
  end




end
