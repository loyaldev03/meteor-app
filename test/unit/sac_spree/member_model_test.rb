require 'test_helper'
require 'sac_spree/spree'

class Spree::MemberModelTest < ActiveSupport::TestCase
  def setup
    Spree.test_mode!
    @club                 = FactoryBot.create(:club_with_spree_api)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
  end

  test 'Sync user with Spree' do
    stub_spree_user_create
    stub_spree_user_update
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_equal user.api_id, '123456789'
    assert_equal user.last_synced_at.to_date, Time.current.to_date
    assert_nil user.last_sync_error
    assert_nil user.last_sync_error_at
    assert_equal user.sync_status, 'synced'
  end

  test 'Save error when sync user with Spree fails' do
    stub_spree_user_create 404
    stub_spree_user_update 404
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_nil user.api_id
    assert_nil user.last_synced_at
    assert_not_nil user.last_sync_error
    assert_equal user.last_sync_error_at.to_date, Time.current.to_date
    assert_equal user.sync_status, 'with_error'
  end
end
