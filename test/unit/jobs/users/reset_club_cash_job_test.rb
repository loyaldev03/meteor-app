require 'test_helper'

class Users::ResetClubCashJobTest < ActiveSupport::TestCase
  def setup_spree_club
    @club                             = FactoryBot.create(:club_with_spree_api)
    @partner                          = @club.partner
    Time.zone                         = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, initial_club_cash_amount: 3, club_id: @club.id)
    @free_terms_of_membership         = FactoryBot.create :free_terms_of_membership, club_id: @club.id
    Spree.test_mode!
    stub_spree_user_create
    stub_spree_user_update
  end

  test 'Spree::CMS PAID users club cash reset every 12 months (club cash less than default)' do
    setup_spree_club
    user_to_create  = FactoryBot.build(:user_with_api)
    user            = enroll_user(user_to_create, @terms_of_membership_with_gateway)

    assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount

    # if club cash is less than "default", then it should add missing club cash.
    [-1, -2, -3].each do |cc_to_substract|
      user.add_club_cash(nil, cc_to_substract, 'removing club cash for test')
      Users::ResetClubCashJob.perform_now(user_id: user.id)
      user.reload
      cc_transaction = user.club_cash_transactions.last
      assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount
      assert_equal cc_transaction.description, 'Reseting Club cash cash amount to 3.0 for paid member.'
      assert_equal cc_transaction.amount, cc_to_substract.abs
      assert_equal user.operations.last.description, "#{cc_to_substract.abs.to_f} club cash was successfully added. Concept: Reseting Club cash cash amount to 3.0 for paid member."
    end
  end

  test 'Spree::CMS PAID users club cash reset every 12 months (club cash more than default)' do
    setup_spree_club
    user_to_create  = FactoryBot.build(:user_with_api)
    user            = enroll_user(user_to_create, @terms_of_membership_with_gateway)

    assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount

    # if club cash is more than default, it should not remove club cash.
    user.add_club_cash(nil, 1, 'adding club cash for test')
    assert_equal user.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + 1
    Users::ResetClubCashJob.perform_now(user_id: user.id)
    assert_equal user.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + 1
  end

  test 'Spree::CMS VIP users club cash reset every 12 months (club cash less than default)' do
    setup_spree_club
    user_to_create         = FactoryBot.build(:user_with_api)
    user                   = enroll_user(user_to_create, @terms_of_membership_with_gateway)
    user.member_group_type = MemberGroupType.find_by(name: 'VIP')
    user.save
    assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + Settings.vip_additional_club_cash

    [-1, -2, -3, -4].each do |cc_to_substract|
      user.add_club_cash(nil, cc_to_substract, 'removing club cash for test')
      Users::ResetClubCashJob.perform_now(user_id: user.id)
      user.reload
      cc_transaction = user.club_cash_transactions.last
      assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + Settings.vip_additional_club_cash
      assert_equal cc_transaction.description, 'Reseting Club cash cash amount to 4.0 for vip member.'
      assert_equal cc_transaction.amount, cc_to_substract.abs
      assert_equal user.operations.last.description, "#{cc_to_substract.abs.to_f} club cash was successfully added. Concept: Reseting Club cash cash amount to 4.0 for vip member."
    end
  end

  test 'Spree::CMS VIP users club cash reset every 12 months (club cash more than default)' do
    setup_spree_club
    user_to_create         = FactoryBot.build(:user_with_api)
    user                   = enroll_user(user_to_create, @terms_of_membership_with_gateway)
    user.member_group_type = MemberGroupType.find_by(name: 'VIP')
    user.save
    assert_equal user.reload.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + Settings.vip_additional_club_cash

    # if club cash is more than default, it should not remove club cash.
    user.add_club_cash(nil, 1, 'adding club cash for test')
    assert_equal user.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + Settings.vip_additional_club_cash + 1
    Users::ResetClubCashJob.perform_now(user_id: user.id)
    assert_equal user.club_cash_amount, @terms_of_membership_with_gateway.initial_club_cash_amount + Settings.vip_additional_club_cash + 1
  end

  test 'Spree::CMS FREE users club cash should not reset every 12 months' do
    setup_spree_club
    user_to_create  = FactoryBot.build(:user_with_api)
    user            = enroll_user(user_to_create, @free_terms_of_membership)

    # assigning club cash manually since it is not being added automatically.
    user.add_club_cash(nil, 3, 'adding club cash for test')
    assert_equal user.reload.club_cash_amount, 3

    Users::ResetClubCashJob.perform_now(user_id: user.id)
    assert_equal user.club_cash_amount, 3
  end
end
