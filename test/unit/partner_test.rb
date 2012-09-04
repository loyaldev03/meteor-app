require 'test_helper'

class PartnerTest < ActiveSupport::TestCase

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

  test "Should not let you save partner with random characters" do
    partner_random = FactoryGirl.build(:partner, :prefix => 'prefix$%$%%#')
    assert !partner_random.valid?
    assert_not_nil partner_random.errors, "Saved with prefix with characters like '$%#%#'"
  end

  test "Should not let you save partner with prefix like 'admin'" do
    partner_admin = FactoryGirl.build(:partner, :prefix => 'billy_admin_2012')
    assert !partner_admin.valid?
    assert_not_nil partner_admin.errors
  end

  test "Should not let you save partner with name like 'admin'" do
    partner_admin = FactoryGirl.build(:partner, :name => 'billy_admin_2012')
    assert !partner_admin.valid?
    assert_not_nil partner_admin.errors
  end

end
