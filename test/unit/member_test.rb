require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  
  test "Should create a member" do
  	member = FactoryGirl.build(:member)
  	assert member.save
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
    member = FactoryGirl.create(:lapsed_member)
    answer = member.bill_membership
    assert !(answer[:code] == Settings.error_codes.success)
  end

  test "Member should not be billed if no credit card is on file." do
    member = FactoryGirl.create(:provisional_member)
    answer = member.bill_membership
    assert (answer[:code] != Settings.error_codes.success)
  end

  test "Insfufficient funds hard decline" do
    paid_member = FactoryGirl.create(:paid_member)
    credit_card = FactoryGirl.create(:credit_card_master_card)
    paid_member.credit_cards << credit_card
    paid_member.save
    answer = paid_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success)
  end

  test "Monthly member should be billed if it is paid or provisional" do
    assert_difference('Operation.count') do
      member = FactoryGirl.create(:provisional_member)
      credit_card = FactoryGirl.create(:credit_card_master_card)
      member.credit_cards << credit_card
      member.save
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      assert (answer[:code] == Settings.error_codes.success)
      assert member.quota == 2
      assert member.recycled_times == 1
      assert member.bill_date == member.next_retry_bill_date
      assert member.next_retry_bill_date == (prev_bill_date + 1.month)
    end
  end

  test "Should not save with an invalid email" do
    member = FactoryGirl.build(:member, :email => 'testing.com.ar')
    member.valid?
    assert_not_nil member.errors, member.errors.full_messages.inspect
  end

  test "Should not be two members with the same email within the same club" do
    tom = FactoryGirl.create(:terms_of_membership_with_gateway)
    member = FactoryGirl.build(:member)
    member.terms_of_membership = tom
    member.save
    member_two = FactoryGirl.build(:member)
    member_two.terms_of_membership = tom
    member_two.valid?
    assert_not_nil member_two, member_two.errors.full_messages.inspect
  end

  test "Should let save two members with the same email in diferents clubs" do
    member = FactoryGirl.create(:member, :club_id => 30)
    member_two = FactoryGirl.build(:member)
    assert member_two.save
  end

  test "Paid member cant be recovered" do
    member = FactoryGirl.create(:paid_member)
    answer = member.recover(4)
    assert answer[:code] == "407"
  end

  test "Lapsed member can be recovered" do
    member = FactoryGirl.create(:lapsed_member)
    answer = member.recover(TermsOfMembership.first)
    assert answer[:code] == Settings.error_codes.success
  end


end
