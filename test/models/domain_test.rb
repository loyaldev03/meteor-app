require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  test 'Save domain with all basic data' do
    domain = FactoryBot.build(:domain)
    assert_difference('Domain.count', 1) { assert domain.save }
  end

  test 'Domain should not be create without a url' do
    domain          = FactoryBot.build(:domain, url: nil)
    domain.club_id  = nil
    assert !domain.save, 'Domain was saved without a url'
  end

  test 'Domain shouldnt be destroyed is its the last one' do
    domain = FactoryBot.create(:domain, url: 'http://prueba.com')
    second_domain = FactoryBot.build(:domain)
    second_domain.save
    second_domain.destroy
    assert !domain.destroy, 'Domain was destroyed when it was the last one'
  end

  test 'Domain should not be destroyed when is associated to club' do
    club    = FactoryBot.create(:simple_club_with_gateway)
    domain  = FactoryBot.create(:domain, url: 'http://prueba.com', club_id: club.id)
    assert !domain.destroy
    assert domain.errors[:base].first[:error].include? 'Cannot destroy last domain. Partner must have at least one domain.'
  end

  test 'Should not save two domains with the same url' do
    domain = FactoryBot.create(:domain, url: 'http://xagax.com.ar')
    second_domain = FactoryBot.build(:domain)
    second_domain.url = domain.url
    second_domain.valid?
    assert_not_nil second_domain.errors, domain.errors.full_messages.inspect
  end

  test 'Should not save a domain without the correct format of url' do
    domain = Domain.new(url: 'xagax.com.ar')
    domain.valid?
    assert_not_nil domain.errors, 'Domain was saved with an invalid url'
  end
end
