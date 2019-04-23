require 'test_helper'

class Users::NillifyClubCashJobTest < ActiveSupport::TestCase
  setup do
    @club                         = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership          = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @club_with_api                = FactoryBot.create(:club_with_api)
    @terms_of_membership_with_api = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    Drupal.enable_integration!
    Drupal.test_mode!
  end

  test 'Removes club cash' do
    @user               = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_club_cash  = @user.club_cash_amount 
    assert_not_equal original_club_cash, 0

    Users::NillifyClubCashJob.perform_now(@user.id)
    assert_equal @user.reload.club_cash_amount, 0
    assert_nil @user.club_cash_expire_date
  end

  test 'Removes club cash if user is related to club with Drupal' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_api)

    Users::NillifyClubCashJob.perform_now(@user.id)
    assert_equal @user.reload.club_cash_amount, 0
    assert_nil @user.club_cash_expire_date
  end
end