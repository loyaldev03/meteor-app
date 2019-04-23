require 'test_helper'

class Users::AssignClubCashJobTest < ActiveSupport::TestCase
  setup do
    @club                         = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership          = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @club_with_api                = FactoryBot.create(:club_with_api)
    @terms_of_membership_with_api = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club_with_api.id)
    Drupal.enable_integration!
    Drupal.test_mode!
  end

  test 'adds club cash when enroll' do
    @user              = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_club_cash = @user.club_cash_amount
    Users::AssignClubCashJob.perform_now(@user.id, 'testing', true)
    assert_equal @user.reload.club_cash_amount, original_club_cash + @terms_of_membership.initial_club_cash_amount
    assert_equal @user.club_cash_expire_date, @user.join_date + 1.year
  end

  test 'adds club cash when is not enroll' do
    @user              = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    original_club_cash = @user.club_cash_amount
    Users::AssignClubCashJob.perform_now(@user.id, 'testing', false)
    assert_equal @user.reload.club_cash_amount, original_club_cash + @terms_of_membership.club_cash_installment_amount
    assert_equal @user.club_cash_expire_date, @user.join_date + 1.year
  end

  test 'does not set club cash expire date when terms of membership is freemium' do
    @terms_of_membership_freemium = FactoryBot.create(:free_terms_of_membership, club_id: @club.id)
    @user                         = enroll_user(FactoryBot.build(:user), @terms_of_membership_freemium)
    Users::AssignClubCashJob.perform_now(@user.id, 'testing')
    assert_nil @user.club_cash_expire_date
  end

  test 'does not set club cash expire date when club is associated to Drupal' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_api)
    Users::AssignClubCashJob.perform_now(@user.id, 'testing')
    assert_nil @user.club_cash_expire_date
  end
end
