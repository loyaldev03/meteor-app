module Campaigns
  class CampaignAllDaysDataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(campaign_id)
      campaign = Campaign.find campaign_id
      campaign.campaign_days.each do |campaign_day| 
        CampaignDataFetcher.new(club_id: campaign.club_id, transport: campaign.transport, campaign_id: campaign.id, date: campaign_day.date).fetch!
      end
      CampaignNotifier.campaign_all_days_fetcher_result(campaign_id: campaign.id).deliver_now
    end
  end
end