require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  setup do
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
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

  test "Member should not be billed if it is not paid or provisional" do
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
    paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = paid_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Monthly member should be billed if it is paid or provisional" do
    assert_difference('Operation.count') do
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
    member_two.valid?
    assert_not_nil member_two, member_two.errors.full_messages.inspect
  end

  test "Should let save two members with the same email in differents clubs" do
    member = FactoryGirl.create(:member, terms_of_membership_id: 20, club_id: 13)
    member_two = FactoryGirl.build(:member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    assert member_two.save, member_two.errors.inspect
  end

  test "Paid member cant be recovered" do
    member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.recover(4)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member with reactivation_times = 5 cant be recovered" do
    member = FactoryGirl.create(:lapsed_member, reactivation_times: 5, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.recover(4)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member can be recovered" do
    member = FactoryGirl.create(:lapsed_member, terms_of_membership: @terms_of_membership_with_gateway, club: @terms_of_membership_with_gateway.club)
    answer = member.recover(@terms_of_membership_with_gateway)
    assert answer[:code] == Settings.error_codes.success, answer[:message]
  end


end
