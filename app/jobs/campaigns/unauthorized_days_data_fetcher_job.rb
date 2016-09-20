module Campaigns
  class UnauthorizedDaysDataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform(transport_setting)
      CampaignDay.joins(:campaign).unauthorized.where(campaigns: {club_id: transport_setting.club_id}).pluck(:date).uniq.each do |date|
        Campaigns::DataFetcherJob.perform_later(club_id: transport_setting.club_id, transport: transport_setting.transport, date: date.to_s)
      end
    end
  end
end