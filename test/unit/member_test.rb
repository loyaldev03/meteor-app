require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  setup do
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    @use_active_merchant = false
  end

  test "Should create a member" do
  	member = FactoryGirl.build(:member)
  	assert !member.save, member.errors.inspect
    member.club =  @terms_of_membership_with_gateway.club
    member.terms_of_membership =  @terms_of_membership_with_gateway
    assert member.save, "member cant be save #{member.errors.inspect}"
  end

  test "Should not create a member without first name" do
    member = FactoryGirl.build(:member, :first_name => nil)
    assert !member.save
  end

  test "Should not create a member without last name" do
    member = FactoryGirl.build(:member, :last_name => nil)
  	assert !member.save
  end

  test "Member should not be billed if it is not active or provisional" do
    member = FactoryGirl.create(:lapsed_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.bill_membership
    assert !(answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Member should not be billed if no credit card is on file." do
    member = FactoryGirl.create(:provisional_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.bill_membership
    assert (answer[:code] != Settings.error_codes.success), answer[:message]
  end

  test "Insfufficient funds hard decline" do
    active_merchant_stubs unless @use_active_merchant
    active_member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = active_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Monthly member should be billed if it is active or provisional" do
    assert_difference('Operation.count', +3) do
      member = FactoryGirl.create(:provisional_member_with_cc, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.quota, 1, "quota is #{member.quota} should be 1"
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal member.bill_date, member.next_retry_bill_date, "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal member.next_retry_bill_date, (prev_bill_date + 1.month), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  test "Should not save with an invalid email" do
    member = FactoryGirl.build(:member, :email => 'testing.com.ar')
    member.valid?
    assert_not_nil member.errors, member.errors.full_messages.inspect
  end

  test "Should not be two members with the same email within the same club" do
    member = FactoryGirl.build(:member)
    member.club =  @terms_of_membership_with_gateway.club
    member.terms_of_membership =  @terms_of_membership_with_gateway
    member.save
    member_two = FactoryGirl.build(:member)
    member_two.club =  @terms_of_membership_with_gateway.club
    member_two.terms_of_membership =  @terms_of_membership_with_gateway
    member_two.email = member.email
    member_two.valid?
    assert_not_nil member_two, member_two.errors.full_messages.inspect
  end

  test "Should let save two members with the same email in differents clubs" do
    member = FactoryGirl.build(:member, email: 'testing@xagax.com' , terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    member.club_id = 1
    member.save
    member_two = FactoryGirl.build(:member, email: 'testing@xagax.com',terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    member_two.club_id = 14
    assert member_two.save, "member cant be save #{member_two.errors.inspect}"
  end

  test "Active member cant be recovered" do
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.recover(4)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member with reactivation_times = 5 cant be recovered" do
    member = FactoryGirl.create(:lapsed_member, reactivation_times: 5, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.recover(4)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member can be recovered" do
    assert_difference('Fulfillment.count') do
      member = FactoryGirl.create(:lapsed_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      answer = member.recover(@terms_of_membership_with_gateway)
      assert answer[:code] == Settings.error_codes.success, answer[:message]
    end
  end

  test "Active member can receive fulfillments" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert member.can_receive_another_fulfillment?
  end

  test "fulfillment" do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.save
    fulfillment.set_as_open!
    assert_difference('Fulfillment.count') do
      fulfillment.renew
    end
  end

  test "Archived fulfillment cant be archived again or opened." do 
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    fulfillment = FactoryGirl.build(:fulfillment)
    fulfillment.member = member
    fulfillment.save
    fulfillment.set_as_open!
    fulfillment.set_as_archived!
    assert_raise(StateMachine::InvalidTransition){ fulfillment.set_as_archived! }
    assert_raise(StateMachine::InvalidTransition){ fulfillment.set_as_open! }
  end

  test "Should let create member with correct format number" do
    ['(+54) 11-4632-5895', '11-4632-5895', '338.560.1829 (5755)', '338.560.1829 int5755', 
       '338.560.1829 x5755', '(801)585-5189', '216.463.8898'].each {|phone| phone 
    member = FactoryGirl.build(:member, phone_number: phone,terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert member.save, "member cant be save #{member.errors.inspect}"
    }

    ['4632-5895()', '()11-4632-5895', '+338.560.1829 (575584964651215465+4)', '+338.560.1829 int5755'].each {|phone| phone 
    member = FactoryGirl.build(:member, phone_number: phone,terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert !member.save, "member cant be save #{member.errors.inspect}"
    }
  end

  test "Should not let create a member with a wrong format zip" do
    ['12345-1234', '12345'].each {|zip| zip
      member = FactoryGirl.build(:member, zip: zip, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      assert member.save, "Member cant be save #{member.errors.inspect}"
    }    
    ['1234-1234', '12345-123', '1234'].each {|zip| zip
      member = FactoryGirl.build(:member, zip: zip, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      assert !member.save, "Member cant be save #{member.errors.inspect}"
    }        

  end

end
