 require 'test_helper'

class CampaignTest < ActiveSupport::TestCase

  setup do    
    @campaign = FactoryGirl.build(:campaign)
  end

  def facebooksetup
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @tsfacebook = FactoryGirl.create(:transport_settings_facebook, :club_id => @club.id) 
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign1 = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id, :initial_date => Time.zone.yesterday)
  end

  test 'Should save campaign when filling all data' do
    assert !@campaign.save, "The campaign #{@campaign.name} was not created."
  end

  test 'Should not save campaign without name' do
    @campaign.name = nil
    assert !@campaign.save, "Campaign was saved without a name"
  end

  test 'Should not save campaign without landing name' do
    @campaign.landing_name = nil
    assert !@campaign.save, "Campaign was saved without landing name"
  end

  test 'Should not save campaign without campaign type' do
    @campaign.campaign_type = nil
    assert !@campaign.save, "Campaign was saved without campaign type"
  end
  test 'Should not save campaign without transport' do  #   @campaign.transport = nil  #   assert !@campaign.save, "Campaign was saved without transport"
  end

  test 'Should not save campaign without transport_campaign_id' do
    @campaign.transport_campaign_id = nil
    assert !@campaign.save, "Campaign was saved without transport_campaign_id"
  end
  
  test 'Should not save campaign without campaign_medium' do
    @campaign.campaign_medium = nil
    assert !@campaign.save, "Campaign was saved without campaign_medium"
  end
  
  test 'Should not save campaign without initial_date date.' do
    @campaign.initial_date = nil
    assert !@campaign.save, "Campaign was saved without initial_date"
  end
 
  test 'Should not save campaign without campaign_medium_version.' do
    @campaign.campaign_medium_version = nil
    assert !@campaign.save, "Campaign was saved without campaign_medium_version"
  end

  test 'Should not save campaign without marketing_code' do
    @campaign.marketing_code = nil
    assert !@campaign.save, "Campaign was saved without marketing_code"
  end

  test 'Should not save campaign without fulfillment_code' do
    @campaign.fulfillment_code = nil
    assert !@campaign.save, "Campaign was saved without   fulfillment_code"
  end

  test 'Should not save campaign with initial_date before today.' do
    @campaign.initial_date = Time.zone.now - 1.days
    assert !@campaign.save, "Campaign was saved with initial_date before today"
  end

  test 'Should not save campaign with finish_date before initial_date.' do
    @campaign.initial_date = Time.zone.now + 3.days
    @campaign.finish_date = Time.zone.now + 2.day
    assert !@campaign.save, "Campaign was saved with finish_date before than initial_date "
  end

  ################################################
  ##############FACEBOOK##########################
  ################################################

  def stubsfacebook  
    answer = Faraday::Response.new(status: 200, body: Hashie::Mash.new(data: [Hashie::Mash.new(date_start: "2014-05-21", date_stop: "2014-05-21", impressions: '170', spend: '2', actions: [Hashie::Mash.new(action_type: 'link_click', value: '8')])]))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  def stubsfacebook_invalid_transport_campaign_id
    answer = Faraday::Response.new(status: 400, body: Hashie::Mash.new(error: Hashie::Mash.new(code:100, message: "Unsupported get request. Object with ID '018607890835' does not exist, cannot be loaded due to missing permissions, or does not support this operation.")))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  def stubsfacebook_invalid_access_token
    answer = Faraday::Response.new(status: 400, body: Hashie::Mash.new(error: Hashie::Mash.new(code: 190, message: "The access token could not be decrypted", type: "OAuthException")))
    Faraday::Connection.any_instance.stubs(:get).returns(answer)
  end

  test 'Should fetch campaign data from facebook' do
    facebooksetup  
    stubsfacebook  
    TasksHelpers.fetch_campaigns_data    
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first    
      assert_equal(@campaign_day.meta, "no_error")
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
      assert_equal(@campaign_day.meta, "invalid_campaign")
      assert_equal(@campaign_day.spent, nil)
      assert_equal(@campaign_day.reached, nil)
      assert_equal(@campaign_day.converted, nil)
    end
  end

  test 'Should not fetch campaign data from facebook when it has invalid access token' do
    facebooksetup  
    stubsfacebook_invalid_access_token 
    TasksHelpers.fetch_campaigns_data   
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first    
      assert_equal(@campaign_day.meta, "unauthorized")
      assert_equal(@campaign_day.spent, nil)
      assert_equal(@campaign_day.reached, nil)
      assert_equal(@campaign_day.converted, nil)
    end
  end  
end
