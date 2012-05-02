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
    assert !(answer[:code] == "000")
  end

  test "Member should be billed if it is paid or provisional" do
    assert_difference('Operation.count') do
      member = FactoryGirl.create(:provisional_member)
      answer = member.bill_membership
      assert (answer[:code] == "000"), answer.inspect
    end
  end

  test "Should not save with an invalid email" do
    member = FactoryGirl.build(:member, :email => 'testing.com.ar')
    member.valid?
    assert_not_nil member.errors, member.errors.full_messages.inspect
  end

  test "Should not be two members with the same email within the same club" do
    member = FactoryGirl.create(:member)
    member_two = FactoryGirl.build(:member)
    member_two.valid?
    assert_not_nil member_two, member_two.errors.full_messages.inspect
  end

  test "Should let save two members with the same email in diferents clubs" do
    member = FactoryGirl.create(:member, :club_id => 30)
    member_two = FactoryGirl.build(:member)
    assert member_two.save
  end

end
