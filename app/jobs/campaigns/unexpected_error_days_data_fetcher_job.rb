module Campaigns
  class UnexpectedErrorDaysDataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(transport_setting)
      CampaignDay.joins(:campaign).unexpected_error.where(campaigns: {club_id: transport_setting.club_id}).select(:campaign_id, :date).each do |date|
        Campaigns::DataFetcherJob.perform_later(transport_setting.club_id, transport_setting.transport, date.to_s)
      end
    end
  end
end