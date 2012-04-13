require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "Shouldn not save partner without name and prefix" do
    partner = FactoryGirl.build(:partner)
    partner.prefix = nil
    partner.name = nil
    assert !partner.save
  end

  test "Should not save two partners with the same name" do
  	first = FactoryGirl.create(:partner, :name => 'billy')
  	assert first.valid?
  	second = FactoryGirl.build(:partner, :name => 'billy')
  	second.valid?
  	assert_not_nil second.errors
  end

  test "Should not save two partnes with the same prefix" do
    first = FactoryGirl.create(:partner, :prefix =>'pre')
    assert first.valid?
    second = FactoryGirl.build(:partner, :prefix =>'pre')
    second.valid?
    assert_not_nil second.errors
  end


end
