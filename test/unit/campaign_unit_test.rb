require 'test_helper'

class CampaignUnitTest < ActiveSupport::TestCase
  setup do
    @campaign = FactoryBot.build(:campaign)
  end

  test 'should generate store URL when campaign_type is store_promotion or newsletter' do
    club = FactoryBot.create(:simple_club_with_gateway)
    FactoryBot.create(:transport_settings_store, club_id: club.id)
    newsletter_campaign = FactoryBot.create(:campaign_newsletter, club_id: club.id)
    assert newsletter_campaign.landing_url.include? newsletter_campaign.club.store_url

    store_promotion_campaign = FactoryBot.create(:campaign_store_promotion, club_id: club.id)
    assert store_promotion_campaign.landing_url.include? store_promotion_campaign.club.store_url
  end

  test 'should generate member_landing_url when campaign_type is NOT store_promotion or newsletter' do
    club                = FactoryBot.create(:simple_club_with_gateway, member_landing_url: 'http://products.onmc.com')
    terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: club.id)
    sloop_campaign      = FactoryBot.create(:campaign, club_id: club.id, terms_of_membership_id: terms_of_membership.id)
    assert sloop_campaign.landing_url.include? sloop_campaign.club.store_url
  end

  test 'should not assign preference group if it belongs to another club' do
    club = FactoryBot.create(:simple_club_with_gateway)
    @campaign.preference_groups << FactoryBot.create(:preference_group, club_id: club.id)
    assert !@campaign.save, 'Campaign allows to assign preference_groups that belongs to another club.'
  end

  test 'should not assign product to campaign if it belongs to another club' do
    club = FactoryBot.create(:simple_club_with_gateway)
    @campaign.products << FactoryBot.create(:random_product, club_id: club.id)
    assert !@campaign.save, 'Campaign allows to assign products that belongs to another club.'
  end

  test 'should not assign product if it has not image_url' do
    club    = FactoryBot.create(:simple_club_with_gateway)
    product = FactoryBot.build(:random_product, club_id: club.id, image_url: nil)
    @campaign.products << product
    assert !@campaign.save, 'Campaign allows to assign products that does not have image_url.'
  end

  test 'Should use Checkout Settings from itself if they are set' do
    club      = FactoryBot.create(:simple_club_with_gateway, checkout_page_footer: 'Club Checkout Page Footer')
    campaign  = FactoryBot.build(:campaign_with_checkout_settings, club_id: club.id, checkout_page_footer: 'Campaign Checkout Page Footer')
    assert_equal 'Campaign Checkout Page Footer', campaign.checkout_settings[:checkout_page_footer], 'Campaign doesn\'t use its checkout settings'
  end

  test 'Should use Checkout Settings from its Club if theirs are not set' do
    club      = FactoryBot.create(:simple_club_with_gateway, checkout_page_footer: 'Club Checkout Page Footer')
    campaign  = FactoryBot.build(:campaign_with_checkout_settings, club_id: club.id, checkout_page_footer: nil)
    assert_equal 'Club Checkout Page Footer', campaign.checkout_settings[:checkout_page_footer], 'Campaign doesn\'t use the Club checkout settings'
  end
end