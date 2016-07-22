require 'test_helper'

class CampaignTest < ActiveSupport::TestCase

  setup do
    @campaign = FactoryGirl.build(:campaign)
  end

  test 'Should save campaign when filling all data' do
    assert !@campaign.save, "The campaign #{@campaign.name} was not created."
  end

  test 'Should not save campaign without name' do
    @campaign.name = nil
    assert !@campaign.save, "Campaign was saved without a name"
  end

  test 'Should not save campaign without transport' do
    @campaign.transport = nil
    assert !@campaign.save, "Campaign was saved without transport"
  end

  test 'Should not save campaign without initial_date date.' do
    @campaign.initial_date = nil
    assert !@campaign.save, "Campaign was saved without initial_date"
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
end
