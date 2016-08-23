module Campaigns
  class UnexpectedErrorDaysDataFetcherJob < ActiveJob::Base
    queue_as :campaigns

    def perform
      unexpected_error_days = CampaignDay.joins(:campaign).unexpected_error.where(campaigns: {club_id: Club.is_enabled.ids}).select(:campaign_id, :date)
      unexpected_error_days.group_by{|campaign_day| campaign_day.campaign.club_id}.each do |club_id, campaign_day_list|
        campaign_day_list.group_by{|campaign_day| campaign_day.campaign.transport}.each do |transport, campaign_days|
          campaign_days.group_by{|campaign_day| campaign_day.date}.each do |date, campaign_days|
            Campaigns::DataFetcherJob.perform_later(club_id: club_id, transport: transport, date: date.to_s)
          end
        end
      end
    end
  end
end