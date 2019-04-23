require 'test_helper'
require 'sac_mailchimp/mailchimp'

class SacMailchimp::MemberModelTest < ActiveSupport::TestCase
  def setup
    SacMailchimp.enable_integration!
    @club                 = FactoryBot.create(:club_with_mkt_client_mailchimp)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    stub_mailchimp
  end

  test 'Sync user with Mailchimp' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    assert_not_nil user.mailchimp_member

    user.mailchimp_member.save!
    user.reload
    assert_equal user.marketing_client_last_synced_at.to_date, Time.current.to_date
    assert user.marketing_client_synced_status, 'synced'
    assert_nil user.marketing_client_last_sync_error
    assert_nil user.marketing_client_last_sync_error_at
  end

  test 'Save error fields when synchronization fails Mailchimp' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_not_nil user.mailchimp_member

    stub_mailchimp_with_error
    user.mailchimp_member.save!
    user.reload
    assert user.marketing_client_last_synced_at.to_date, Time.current.to_date
    assert user.marketing_client_synced_status, 'error'
    assert_not_nil user.marketing_client_last_sync_error
    assert_equal user.marketing_client_last_sync_error_at.to_date, Time.current.to_date
  end

  test 'Does not synchronize user if it has testing email' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_not_nil user.mailchimp_member

    ['mailinator.com', 'test.com', 'noemail.com'].each do |testing_domain|
      user.email = "testing123@#{testing_domain}"
      user.mailchimp_member.save!
      assert user.marketing_client_last_sync_error.include? 'Email address looks fake or invalid.'
    end
  end
end
