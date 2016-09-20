module Campaigns
  class UnexpectedErrorDaysDataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform
      Club.is_enabled.each do |club|
        unexpected_error_days = CampaignDay.joins(:campaign).unexpected_error.where(campaigns: { club_id: club.id }).select(:campaign_id, :date)
        unexpected_error_days.group_by{|campaign_day| campaign_day.campaign.transport}.each do |transport, days|
          days.group_by{|day| day.date}.keys.each do |date|
            Campaigns::DataFetcherJob.perform_later(club_id: club.id, transport: transport, date: date.to_s)
          end
        end
      end
    end
  end
end