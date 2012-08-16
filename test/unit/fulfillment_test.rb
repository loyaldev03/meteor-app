require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  
  setup do 
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
  end

  test "active member can receive fulfillments" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert member.can_receive_another_fulfillment?
  end

  test "fulfillment" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert_difference('Fulfillment.count') do  
      fulfillment = FactoryGirl.build(:fulfillment)
      fulfillment.member = member
      fulfillment.save
      fulfillment.renew!
    end
  end

  test "Archived fulfillment cant be archived again or opened." do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.save
    fulfillment.set_as_processing!
    assert_raise(StateMachine::InvalidTransition){ fulfillment.set_as_processing! }
  end

  test "Should send fulfillments on acepted applied member" do
    member = FactoryGirl.create(:applied_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club) 
    enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)
    assert_difference('Fulfillment.count',2) do
      member.set_as_provisional!
    end
  end
end
