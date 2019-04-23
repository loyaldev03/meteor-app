require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase
  def setup
    @club                = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    @credit_card         = @user.active_credit_card
    active_merchant_stubs_payeezy
  end

  test 'Should not let activate a blacklisted credit card' do
    credit_card_one = FactoryBot.create(:credit_card)
    credit_card_two = FactoryBot.create(:credit_card_master_card)
    assert !(credit_card_one.blacklist && credit_card_one.activate), "blacklisted credit card activated. #{credit_card_two.errors.inspect}"
  end

  test 'Should not let destroy credit card if is active' do
    assert !@credit_card.destroy
    assert @credit_card.errors[:active].include? 'Credit card is set as active. It cannot be destroyed.'
  end

  test 'Should not let destroy credit card if it is the last one' do
    @credit_card.deactivate
    assert !@credit_card.destroy
    assert @credit_card.errors[:credit_card].include? 'The member should have at least one credit card.'
  end

  test 'Should not let destroy credit card if user was chargebacked' do
    second_credit_card = FactoryBot.create(:credit_card_master_card, user_id: @user.id, active: false)
    @user.operations << FactoryBot.create(:operation, operation_type: 110)
    assert !second_credit_card.destroy
    assert second_credit_card.errors[:user].include? 'The member was chargebacked. It cannot be destroyed.'
  end

  test 'CC dates validation within club with negative offset' do
    @club.time_zone = 'International Date Line West'
    @club.save!
    assert_equal Time.now.in_time_zone(@club.time_zone).formatted_offset, @credit_card.user.get_offset_related
  end

  test 'CC dates validation within club with positive offset' do
    @club.time_zone = 'Pacific/Kiritimati'
    @club.save!
    assert_equal Time.now.in_time_zone(@club.time_zone).formatted_offset, @credit_card.user.get_offset_related
  end

  test 'CC dates validation within club with offset = +00:00' do
    @club.time_zone = 'UTC'
    @club.save!
    assert_equal Time.now.in_time_zone(@club.time_zone).formatted_offset, @credit_card.user.get_offset_related
  end
end
