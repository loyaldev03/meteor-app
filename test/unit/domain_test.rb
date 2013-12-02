require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  setup do
    stubs_solr_index
  end

  test "Domain should not be create without a url" do
    domain = FactoryGirl.build(:domain, :url => nil)
    domain.club_id = nil
    assert !domain.save, "Domain was saved without a url"
  end

  test "Domain shouldnt be destroyed is its the last one" do
    domain = FactoryGirl.create(:domain, :url => 'http://prueba.com')
    second_domain = FactoryGirl.build(:domain)
    second_domain.save
    second_domain.destroy     
    assert !domain.destroy, "Domain was destroyed when it was the last one"    
  end

  test "Should not save two domains with the same url" do
    domain = FactoryGirl.create(:domain, :url => 'http://xagax.com.ar')
    second_domain = FactoryGirl.build(:domain)
    second_domain.url = domain.url
    second_domain.valid?
    assert_not_nil second_domain.errors, domain.errors.full_messages.inspect
  end    
  
  test "Should not save a domain without the correct format of url" do
    domain = Domain.new(:url => 'xagax.com.ar')
    domain.valid?
    assert_not_nil domain.errors, "Domain was saved with an invalid url" 
  end 

end
