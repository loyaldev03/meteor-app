# encoding: utf-8
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
    enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => active_member.id)
    answer = active_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Monthly member should be billed if it is active or provisional" do
    assert_difference('Operation.count', 4) do
      member = FactoryGirl.create(:provisional_member_with_cc, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)
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

  test "active member cant be recovered" do
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
    assert_difference('Fulfillment.count',2) do
      member = FactoryGirl.create(:lapsed_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
      enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)
      answer = member.recover(@terms_of_membership_with_gateway)
      assert answer[:code] == Settings.error_codes.success, answer[:message]
      assert_equal 'provisional', member.status, "Status was not updated."
      assert_equal 1, member.reactivation_times, "Reactivation_times was not updated."
    end
  end

  test "Lapsed member can be recovered unless it needs approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval)
    member = FactoryGirl.create(:lapsed_member, terms_of_membership: @tom_approval, club: @tom_approval.club)
    enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)
    answer = member.recover(@terms_of_membership_with_gateway)
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', member.status
    assert_equal 1, member.reactivation_times
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

  test "If member is rejected, when recovering it should increment reactivation_times" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval)
    member = FactoryGirl.create(:applied_member, terms_of_membership: @tom_approval, club: @tom_approval.club)
    enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => member.id)   
    member.set_as_canceled!
    answer = member.recover(@terms_of_membership_with_gateway)
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', member.status
    assert_equal 1, member.reactivation_times
  end

  test "Should reset club_cash when member is canceled" do
    member = FactoryGirl.create(:provisional_member_with_cc, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club, :club_cash_amount => 200)
    member.set_as_canceled
    assert_equal 0, member.club_cash_amount, "The member is #{member.status} with $#{member.club_cash_amount}"
  end

  test "Member should be saved with first_name and last_name with numbers or acents." do
    member = FactoryGirl.build(:member)
    assert !member.save, member.errors.inspect
    member.club =  @terms_of_membership_with_gateway.club
    member.terms_of_membership =  @terms_of_membership_with_gateway
    member.first_name = 'Billy 3ro'
    member.last_name = 'Sáenz'
    assert member.save, "member cant be save #{member.errors.inspect}"
  end

  test "Should not deduct more club_cash than the member has" do
    member = FactoryGirl.create(:provisional_member_with_cc, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club, :club_cash_amount => 200)
    member.add_club_cash(-300)
    assert_equal 200, member.club_cash_amount, "The member is #{member.status} with $#{member.club_cash_amount}"
  end

  test "if active member is blacklisted, should have cancel date set " do
    member = FactoryGirl.create(:active_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    cancel_date = member.cancel_date
    # 2 operations : cancel and blacklist
    assert_difference('Operation.count', 2) do
      member.blacklist(nil, "Test")
    end
    m = Member.find member.uuid
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
    assert_equal m.blacklisted, true
  end

  test "if lapsed member is blacklisted, it should not be canceled again" do
    member = FactoryGirl.create(:lapsed_member, reactivation_times: 5, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    cancel_date = member.cancel_date
    assert_difference('Operation.count', 1) do
      member.blacklist(nil, "Test")
    end
    m = Member.find member.uuid
    assert_not_nil m.cancel_date 
    assert_equal m.cancel_date.to_date, cancel_date.to_date
    assert_equal m.blacklisted, true
  end

  test "If member's email contains '@noemail.com' it should not send emails." do
    member = FactoryGirl.create(:lapsed_member, reactivation_times: 5, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club, email: "testing@noemail.com")
    assert_difference('Operation.count', 1) do
      Communication.deliver!(:active,member)
    end
    assert_equal member.operations.last.description, "The email contains '@noemail.com' which is an empty email. The email won't be sent."
  end

end