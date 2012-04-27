require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  
  # test "Should create a member" do
  # 	member = FactoryGirl.build(:member)
  # 	assert member.save
  # end

  # test "Should not create a member without first name" do
  #   member = FactoryGirl.build(:member, :first_name => nil)
  #   assert !member.save
  # end

  test "Should not create a member without last name" do
    member = FactoryGirl.build(:member, :last_name => nil)
  	assert !member.save
  end

  test "Member should not be billed if it is not paid or provisional" do
    member = FactoryGirl.create(:lapsed_member)
    answer = member.bill_membership
    assert !(answer[:code] == "000")
  end

end
