require 'test_helper'

class DomainTest < ActiveSupport::TestCase

  test "Domain should not be create without a url" do
	domain = FactoryGirl.build(:domain, :url => nil)
	domain.club_id = nil
	assert !domain.save, "Domain was saved without a club_id"
  end

	test "Domain shouldnt be destroyed is its the last one" do
		first_domain = FactoryGirl.create(:domain, :url => 'http://prueba.com')
		second_domain = FactoryGirl.create(:domain, :url => 'http://prueba2.com')

  first_domain.destroy
  assert !second_domain.destroy, "Domain was destroyed when it was the last one"    
  end

  test "Should not save two domains with the same url" do
	domain = FactoryGirl.create(:domain, :url => 'http://xagax.com.ar')
	assert domain.valid?
	second_domain = FactoryGirl.build(:domain, :url => 'http://xagax.com.ar')
	second_domain.valid?
	assert_not_nil second_domain.errors
  end	
  
  test "Should not save a domain without the correct format of url" do
  	domain = FactoryGirl.build(:domain, :url => 'xagax.com.ar')
	domain.valid?
	assert_not_nil domain.errors, "Domain was saved with an invalid url" 
  end 

end
