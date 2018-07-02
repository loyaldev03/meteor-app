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

  def mailchimpsetup
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @tsmailchimp = FactoryGirl.create(:transport_settings_mailchimp, :club_id => @club.id) 
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign2 = FactoryGirl.create(:campaign_mailchimp, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id, :initial_date => Time.zone.yesterday)
  end

  test 'Should save campaign when filling all data' do
    assert !@campaign.save, "The campaign #{@campaign.name} was not created."
  end

  test 'Should not save campaign without name' do
    @campaign.name = nil
    assert !@campaign.save, "Campaign was saved without a name"
  end

  test 'Should not save campaign without title' do
    @campaign.title = nil
    assert !@campaign.save, "Campaign was saved without a title"
  end

  test 'Should not save campaign without landing name' do
    @campaign.landing_name = nil
    assert !@campaign.save, "Campaign was saved without landing name"
  end

  test 'Should not save campaign without campaign type' do
    @campaign.campaign_type = nil
    assert !@campaign.save, "Campaign was saved without campaign type"
  end

  test 'Should not save campaign without transport' do  
     @campaign.transport = nil  
     assert !@campaign.save, "Campaign was saved without transport"
  end

  test 'Should not save campaign without transport_campaign_id' do
    @campaign.transport_campaign_id = nil    
    assert !@campaign.save, "Campaign was saved without transport_campaign_id"
  end

  test 'Should not allow transport_campaign_id null if it has campaign_days associated' do
    club = FactoryGirl.create(:simple_club_with_gateway)
    terms_of_membership = FactoryGirl.create(:terms_of_membership, :club_id => club.id)
    campaign = FactoryGirl.create(:campaign, :club_id => club.id, :terms_of_membership_id => terms_of_membership.id, :initial_date => Time.zone.yesterday)
    campaign_days = FactoryGirl.create(:campaign_day, :campaign_id => campaign.id)
    campaign.reload    
    campaign.transport_campaign_id = nil
    assert !campaign.save, "Campaign was saved without transport_campaign_id with campaign_days associated"
  end
  
  test 'Should not save campaign without utm_medium' do
    @campaign.utm_medium = nil
    assert !@campaign.save, "Campaign was saved without utm_medium"
  end
  
  test 'Should not save campaign without initial_date date.' do
    @campaign.initial_date = nil
    assert !@campaign.save, "Campaign was saved without initial_date"
  end
 
  test 'Should not save campaign without utm_content.' do
    @campaign.utm_content = nil
    assert !@campaign.save, "Campaign was saved without utm_content"
  end

  test 'Should not save campaign without audience' do
    @campaign.audience = nil
    assert !@campaign.save, "Campaign was saved without audience"
  end

  test 'Should not save campaign without campaign_code' do
    @campaign.campaign_code = nil
    assert !@campaign.save, "Campaign was saved without campaign_code"
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

  test 'should generate store URL when campaign_type is store_promotion or newsletter' do    
    club = FactoryGirl.create(:simple_club_with_gateway)
    transport_setting = FactoryGirl.create(:transport_settings_store, :club_id => club.id)    
    newsletter_campaign = FactoryGirl.create(:campaign_newsletter, :club_id => club.id)    
    assert newsletter_campaign.landing_url.include? newsletter_campaign.club.store_url

    store_promotion_campaign = FactoryGirl.create(:campaign_store_promotion, :club_id => club.id)
    assert store_promotion_campaign.landing_url.include? store_promotion_campaign.club.store_url 
  end

  test 'should generate member_landing_url when campaign_type is NOT store_promotion or newsletter' do    
    club = FactoryGirl.create(:simple_club_with_gateway, :member_landing_url => 'http://products.onmc.com')    
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => club.id)
    sloop_campaign = FactoryGirl.create(:campaign, :club_id => club.id, :terms_of_membership_id => terms_of_membership.id)
    assert sloop_campaign.landing_url.include? sloop_campaign.club.store_url    
  end

  test 'should not assign preference group if it belongs to another club' do
    club = FactoryGirl.create(:simple_club_with_gateway)    
    @campaign.preference_groups <<  FactoryGirl.create(:preference_group, :club_id => club.id)
    assert !@campaign.save, "Campaign allows to assign preference_groups that belongs to another club."
  end

  test 'should not assign product to campaign if it belongs to another club' do
    club = FactoryGirl.create(:simple_club_with_gateway)    
    @campaign.products <<  FactoryGirl.create(:random_product, :club_id => club.id)
    assert !@campaign.save, "Campaign allows to assign products that belongs to another club."
  end

  test 'should not assign product if it has not image_url'do
    club = FactoryGirl.create(:simple_club_with_gateway)
    product = FactoryGirl.build(:random_product, :club_id => club.id, :image_url => nil)
    @campaign.products << product
    assert !@campaign.save, "Campaign allows to assign products that does not have image_url."
  end

  test 'Should use Checkout Settings from itself if they are set' do
    club = FactoryGirl.create(:simple_club_with_gateway, checkout_page_footer: 'Club Checkout Page Footer')
    campaign = FactoryGirl.build(:campaign_with_checkout_settings, club_id: club.id, checkout_page_footer: 'Campaign Checkout Page Footer')
    assert_equal 'Campaign Checkout Page Footer', campaign.checkout_settings[:checkout_page_footer], 'Campaign doesn\'t use its checkout settings'
  end

  test 'Should use Checkout Settings from its Club if theirs are not set' do
    club = FactoryGirl.create(:simple_club_with_gateway, checkout_page_footer: 'Club Checkout Page Footer')
    campaign = FactoryGirl.build(:campaign_with_checkout_settings, club_id: club.id, checkout_page_footer: nil)
    assert_equal 'Club Checkout Page Footer', campaign.checkout_settings[:checkout_page_footer], 'Campaign doesn\'t use the Club checkout settings'
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
      assert_equal(@campaign_day.meta, "unauthorized")
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end

  ################################################
  ##############MAILCHIMP#########################
  ################################################  

  def stubsmailchimp    
    answer = Gibbon::Response.new({body: {'emails_sent' => 3305, 'clicks' => {'unique_subscriber_clicks' => 104}}})
    Gibbon::Request.any_instance.stubs(:retrieve).returns(answer)
  end

  def stubsmailchimp_invalid_transport_campaign_id    
    answer = Gibbon::MailChimpError.new({}, {status_code:404, body: {"type"=>"http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/", "title"=>"Resource Not Found", 'status' => 404, "detail"=>"The requested resource could not be found.", "instance"=>""}})
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
  end

  def stubsmailchimp_invalid_api_key
    answer = Gibbon::MailChimpError.new({}, {status_code:401, body: {'type'=>'http://developer.mailchimp.com/documentation/mailchimp/guides/error-glossary/', 'title'=>'API Key Invalid', 'status' => 401, 'detail'=>"Your API key may be invalid, or you've attempted to access the wrong datacenter.", "instance"=>""}})
    Gibbon::Request.any_instance.stubs(:retrieve).raises(answer)
  end

  test 'Should fetch campaign data from mailchimp' do
    mailchimpsetup  
    stubsmailchimp
    TasksHelpers.fetch_campaigns_data        
    assert_difference('CampaignDay.count', 0) do
      @campaign_day = CampaignDay.first    
      assert_equal(@campaign_day.meta, "no_error")
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
      assert_equal(@campaign_day.meta, "invalid_campaign")
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
      assert_equal(@campaign_day.meta, "unauthorized")
      assert_nil @campaign_day.spent
      assert_nil @campaign_day.reached
      assert_nil @campaign_day.converted
    end
  end
end
