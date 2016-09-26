module Campaigns
  class DataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(club_id:, transport:, date: nil, campaign_id: nil)
      if date
        CampaignDataFetcher.new(club_id: club_id, transport: transport, date: date, campaign_id: campaign_id).fetch!
      elsif campaign_id
        CampaignDay.where(campaign_id: campaign_id).pluck(:date).each do |day|
          CampaignDataFetcher.new(club_id: club_id, transport: transport, date: day, campaign_id: campaign_id).fetch!
        end
        CampaignNotifier.campaign_all_days_fetcher_result(campaign_id: campaign_id).deliver_later
      else
        Auditory.report_issue("DataFetcherJob", 'No date or campaign_id provided.', { club_id: club_id })
      end
    end
  end
end