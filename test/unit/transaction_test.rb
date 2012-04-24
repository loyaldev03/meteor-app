require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.build(:agent)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
  end

  test "save operation" do
    assert_difference('Operation.count') do
      Auditory.audit!(@current_agent, @member, "test")
    end
  end
end
