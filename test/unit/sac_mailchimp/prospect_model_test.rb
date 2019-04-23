require 'test_helper'
require 'sac_mailchimp/mailchimp'

class SacMailchimp::ProspectModelTest < ActiveSupport::TestCase
  def setup
    SacMailchimp.enable_integration!
    @club = FactoryBot.create(:club_with_mkt_client_mailchimp)
    stub_mailchimp
  end

  def stub_mailchimp
    answer = Gibbon::Response.new(body: { 'id' => '85c4a5155adbba664e2757c7cde53ba7', 'email_address' => 'pepemari@hotmail.com', 'unique_email_id' => '273ebe7b0e', 'email_type' => 'html', 'status' => 'subscribed', 'merge_fields' => { 'FNAME' => 'tonu', 'LNAME' => 'ujyyhh', 'CITY' => 'city', 'STATUS' => 'provisional', 'TOMID' => 376, 'MSINCEDATE' => '2019-03-11', 'JOINDATE' => '2019-03-11', 'CANCELDATE' => ' ', 'AUDIENCE' => 'all', 'ZIP' => '65941', 'CTYPE' => 'sloop', 'MEDIUM' => 'display', 'PRODUCTSKU' => 'NTWOTONEMUGTONYSTEWART', 'EAMOUNT' => 1.95, 'IAMOUNT' => 14.95, 'BILLDATE' => '2019-04-10', 'EXTERNALID' => ' ', 'GENDER' => ' ', 'PHONE' => '+1 (123) 1233122', 'BIRTHDATE' => ' ', 'PREF1' => 'Wallace, Mike', 'PREF2' => ' ', 'PREF3' => ' ', 'STATE' => 'MA', 'LANDINGURL' => 'http://membertest.onmc.com/select-with-images?utm_campaign=sloop&utm_source=facebook&utm_medium=display&utm_content=banner_some&audience=all&campaign_code=xeeb2clomqu3af4q', 'PREF4' => ' ', 'CJOINDATE' => '2019-03-11', 'MEMBERID' => '11349964381', 'ADDRESS' => '12 th address', 'VIPMEMBER' => 'false' }, 'stats' => { 'avg_open_rate' => 0, 'avg_click_rate' => 0 }, 'ip_signup' => ' ', 'timestamp_signup' => ' ', 'ip_opt' => '50.116.16.84', 'timestamp_opt' => '2019-03-11T13:19:11+00:00', 'member_rating' => 2, 'last_changed' => '2019-03-11T13:19:11+00:00', 'language' => ' ', 'vip' => false, 'email_client' => ' ', 'location' => { 'latitude' => 0, 'longitude' => 0, 'gmtoff' => 0, 'dstoff' => 0, 'country_code' => ' ', 'timezone' => ' ' }, 'tags_count' => 0, 'tags' => [], 'list_id' => 'd38bcbca86', '_links' => [{ 'rel' => 'self', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json' }, { 'rel' => 'parent', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json' }, { 'rel' => 'update', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'PATCH', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PATCH.json' }, { 'rel' => 'upsert', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'PUT', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json', 'schema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PUT.json' }, { 'rel' => 'delete', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7', 'method' => 'DELETE' }, { 'rel' => 'activity', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/activity', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Activity/Response.json' }, { 'rel' => 'goals', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/goals', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Goals/Response.json' }, { 'rel' => 'notes', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/notes', 'method' => 'GET', 'targetSchema' => 'https://us8.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Notes/CollectionResponse.json' }, { 'rel' => 'delete_permanent', 'href' => 'https://us8.api.mailchimp.com/3.0/lists/d38bcbca86/members/85c4a5155adbba664e2757c7cde53ba7/actions/delete-permanent', 'method' => 'POST' }] })
    Gibbon::Request.any_instance.stubs(:retrieve).returns(answer)
    Gibbon::Request.any_instance.stubs(:create).returns(answer)
    Gibbon::Request.any_instance.stubs(:update).returns(answer)
  end

  def stub_mailchimp_with_error
    answer = Gibbon::MailChimpError.new('invalid email', detail: 'Email address looks fake or invalid.', body: { 'status' => 100 }, title: 'Synchronization canceled.')
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
    Gibbon::Request.any_instance.stubs(:create).returns(answer)
    Gibbon::Request.any_instance.stubs(:update).returns(answer)
  end

  test 'Sync prospect with Mailchimp' do
    prospect = FactoryBot.create(:prospect, club_id: @club.id)
    assert_not_nil prospect.mailchimp_prospect
    assert prospect.need_sync_to_marketing_client

    prospect.mailchimp_prospect.save! @club
    assert_equal prospect.reload.marketing_client_sync_result, 'Success'
  end

  test 'Save error fields when synchronization fails Mailchimp' do
    prospect = FactoryBot.create(:prospect, club_id: @club.id)
    assert_not_nil prospect.mailchimp_prospect

    stub_mailchimp_with_error
    prospect.mailchimp_prospect.save! @club
    assert_equal prospect.reload.marketing_client_sync_result, 'Email address looks fake or invalid.'
  end

  test 'Does not synchronize prospect if it has testing email' do
    prospect = FactoryBot.create(:prospect, club_id: @club.id)
    assert_not_nil prospect.mailchimp_prospect

    ['mailinator.com', 'test.com', 'noemail.com'].each do |testing_domain|
      prospect.email = "testing123@#{testing_domain}"
      prospect.mailchimp_prospect.save! @club
      assert_equal prospect.reload.marketing_client_sync_result, 'Email address looks fake or invalid. Synchronization was canceled.'
    end
  end
end
