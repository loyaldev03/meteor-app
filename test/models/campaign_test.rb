class CampaignTest < ActiveSupport::TestCase
  setup do
    @campaign = FactoryBot.build(:campaign)
  end

  test 'Save campaign when filling all data' do
    @campaign.club                = FactoryBot.create(:simple_club_with_gateway)
    @campaign.terms_of_membership = FactoryBot.create(:terms_of_membership, club_id: @campaign.club_id)
    assert @campaign.save, "The campaign #{@campaign.name} was not created."
  end

  test 'Should not save campaign without name' do
    @campaign.name = nil
    assert !@campaign.save, 'Campaign was saved without a name'
  end

  test 'Should not save campaign without title' do
    @campaign.title = nil
    assert !@campaign.save, 'Campaign was saved without a title'
  end

  test 'Should not save campaign without landing name' do
    @campaign.landing_name = nil
    assert !@campaign.save, 'Campaign was saved without landing name'
  end

  test 'Should not save campaign without campaign type' do
    @campaign.campaign_type = nil
    assert !@campaign.save, 'Campaign was saved without campaign type'
  end

  test 'Should not save campaign without transport' do
    @campaign.transport = nil
    assert !@campaign.save, 'Campaign was saved without transport'
  end

  test 'Should not save campaign without transport_campaign_id' do
    @campaign.transport_campaign_id = nil
    assert !@campaign.save, 'Campaign was saved without transport_campaign_id'
  end

  test 'Should not allow transport_campaign_id null if it has campaign_days associated' do
    club                = FactoryBot.create(:simple_club_with_gateway)
    terms_of_membership = FactoryBot.create(:terms_of_membership, club_id: club.id)
    campaign            = FactoryBot.create(:campaign, club_id: club.id, terms_of_membership_id: terms_of_membership.id, initial_date: Time.zone.yesterday)
    FactoryBot.create(:campaign_day, campaign_id: campaign.id)
    campaign.reload.transport_campaign_id = nil
    assert !campaign.save
    assert campaign.errors[:transport_campaign_id].include? "can't be blank"
  end

  test 'Should not allow set initial_date in the past if it has campaign_days associated' do
    club                = FactoryBot.create(:simple_club_with_gateway)
    terms_of_membership = FactoryBot.create(:terms_of_membership, club_id: club.id)
    campaign            = FactoryBot.create(:campaign, club_id: club.id, terms_of_membership_id: terms_of_membership.id, initial_date: Time.zone.yesterday)
    FactoryBot.create(:campaign_day, campaign_id: campaign.id)
    campaign.reload.initial_date = Time.current - 10.days
    assert !campaign.save
    assert campaign.errors[:initial_date].include? "must be after #{Time.current.to_date}"
  end

  test 'Should not save campaign without utm_medium' do
    @campaign.utm_medium = nil
    assert !@campaign.save, 'Campaign was saved without utm_medium'
  end

  test 'Should not save campaign without initial_date date.' do
    @campaign.initial_date = nil
    assert !@campaign.save, 'Campaign was saved without initial_date'
  end

  test 'Should not save campaign without utm_content.' do
    @campaign.utm_content = nil
    assert !@campaign.save, 'Campaign was saved without utm_content'
  end

  test 'Should not save campaign without audience' do
    @campaign.audience = nil
    assert !@campaign.save, 'Campaign was saved without audience'
  end

  test 'Should not save campaign without campaign_code' do
    @campaign.campaign_code = nil
    assert !@campaign.save, 'Campaign was saved without campaign_code'
  end

  test 'Should not save campaign with initial_date before today.' do
    @campaign.initial_date = Time.zone.now - 1.days
    assert !@campaign.save, 'Campaign was saved with initial_date before today'
  end

  test 'Should not save campaign with finish_date before initial_date.' do
    @campaign.initial_date  = Time.zone.now + 3.days
    @campaign.finish_date   = Time.zone.now + 2.day
    assert !@campaign.save, 'Campaign was saved with finish_date before than initial_date'
  end
end
