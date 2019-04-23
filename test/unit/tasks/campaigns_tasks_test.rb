require 'test_helper'

class CampaignsTasksTest < ActiveSupport::TestCase
  def facebooksetup
    @club = FactoryBot.create(:simple_club_with_gateway)
    @tsfacebook = FactoryBot.create(:transport_settings_facebook, club_id: @club.id)
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @campaign1 = FactoryBot.create(:campaign, club_id: @club.id, terms_of_membership_id: @terms_of_membership.id, initial_date: Time.zone.yesterday)
  end

  def mailchimpsetup
    @club = FactoryBot.create(:simple_club_with_gateway)
    @tsmailchimp = FactoryBot.create(:transport_settings_mailchimp, club_id: @club.id)
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @campaign2 = FactoryBot.create(:campaign_mailchimp, club_id: @club.id, terms_of_membership_id: @terms_of_membership.id, initial_date: Time.zone.yesterday)
  end

  def stubsfacebook
    answer = Faraday::Response.new(status: 200, body: Hashie::Mash.new(data: [Hashie::Mash.new(date_start: '2014-05-21', date_stop: '2014-05-21', impressions: '170', spend: '2', actions: [Hashie::Mash.new(action_type: 'link_click', value: '8')])]))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  def stubsfacebook_invalid_transport_campaign_id
    answer = Faraday::Response.new(status: 400, body: Hashie::Mash.new(error: Hashie::Mash.new(code: 100, message: "Unsupported get request. Object with ID '018607890835' does not exist, cannot be loaded due to missing permissions, or does not support this operation.")))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  def stubsfacebook_invalid_access_token
    answer = Faraday::Response.new(status: 400, body: Hashie::Mash.new(error: Hashie::Mash.new(code: 190, message: 'The access token could not be decrypted', type: 'OAuthException')))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  def stubsmailchimp
    answer = Gibbon::Response.new(body: { 'emails_sent' => 3305, 'clicks' => { 'unique_subscriber_clicks' => 104 } })
    Gibbon::Request.any_instance.stubs(:retrieve).returns(answer)
  end

  def stubsmailchimp_invalid_transport_campaign_id
    answer = Gibbon::MailChimpError.new({}, status_code: 404, body: { 'type' => 'http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/', 'title' => 'Resource Not Found', 'status' => 404, 'detail' => 'The requested resource could not be found.', 'instance' => '' })
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
  end

  def stubsmailchimp_invalid_api_key
    answer = Gibbon::MailChimpError.new({}, status_code: 401, body: { 'type' => 'http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/', 'title' => 'API Key Invalid', 'status' => 401, 'detail' => "Your API key may be invalid, or you've attempted to access the wrong datacenter.", 'instance' => '' })
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
  end

  test 'Should fetch campaign data from facebook' do
    facebooksetup
    stubsfacebook
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'no_error')
      assert_equal(@campaign_day.spent, 2)
      assert_equal(@campaign_day.reached, 170)
      assert_equal(@campaign_day.converted, 8)
    end
  end

  test 'Should not fetch campaign data from facebook when transport_campaign_id is invalid' do
    facebooksetup
    stubsfacebook_invalid_transport_campaign_id
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'invalid_campaign')
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end

  test 'Should not fetch campaign data from facebook when it has invalid access token' do
    facebooksetup
    stubsfacebook_invalid_access_token
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'unauthorized')
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end

  test 'Should fetch campaign data from mailchimp' do
    mailchimpsetup
    stubsmailchimp
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'no_error')
      assert_equal(@campaign_day.spent, 0)
      assert_equal(@campaign_day.reached, 3305)
      assert_equal(@campaign_day.converted, 104)
    end
  end

  test 'Should not fetch campaign data from mailchimp when transport_campaign_id is invalid' do
    mailchimpsetup
    stubsmailchimp_invalid_transport_campaign_id
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'invalid_campaign')
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end

  test 'Should not fetch campaign data from mailchimp when it has invalid access token' do
    mailchimpsetup
    stubsmailchimp_invalid_api_key
    TasksHelpers.fetch_campaigns_data
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first
      assert_equal(@campaign_day.meta, 'unauthorized')
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end
end
