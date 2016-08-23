module Campaigns
  class DataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(club_id, transport, date = nil, campaign_id = nil)
      if date
        CampaignDataFetcher.new(club_id: club_id, transport: transport, date: date, campaign_id: campaign_id).fetch!
      elsif campaign_id
        campaign.campaign_days.each do |campaign_day| 
          CampaignDataFetcher.new(club_id: club_id, transport: transport, date: campaign_day.date, campaign_id: campaign_id).fetch!
        end
        CampaignNotifier.campaign_all_days_fetcher_result(campaign_id: campaign.id).deliver_now
      end
    end
  end
end