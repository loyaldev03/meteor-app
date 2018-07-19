require 'test_helper'

class AgentTest < ActiveSupport::TestCase
  test "Shouldnt be two users with samen username" do
    first = FactoryBot.create(:agent, :username => 'billy')
    assert first.valid?
    second = FactoryBot.build(:agent, :username => 'billy')
    second.valid?
    assert_not_nil second.errors
  end

  test "Should not save an username with more than 20 characters" do
  	user = FactoryBot.build(:agent, :username => '123456789123456789123')
  	assert !user.save, "User was saved with a very long username"
  end


end
