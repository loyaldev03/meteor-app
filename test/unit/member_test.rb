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

end
