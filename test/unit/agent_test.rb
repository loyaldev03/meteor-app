require 'test_helper'

class AgentTest < ActiveSupport::TestCase

  test "Shouldnt be two users with samen username" do
    first = FactoryGirl.create(:agent, :username => 'billy')
    assert first.valid?
    second = FactoryGirl.build(:agent, :username => 'billy')
    second.valid?
    assert_not_nil second.errors
  end


end
