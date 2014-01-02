require 'test_helper'

class AgentTest < ActiveSupport::TestCase
  test "Shouldnt be two users with samen username" do
    first = FactoryGirl.create(:agent, :username => 'billy')
    assert first.valid?
    second = FactoryGirl.build(:agent, :username => 'billy')
    second.valid?
    assert_not_nil second.errors
  end

  test "Should not save a username with more than 20 characters" do
  	user = FactoryGirl.build(:agent, :username => '123456789123456789123')
  	assert !user.save, "User was saved with a very long username"
  end


end
