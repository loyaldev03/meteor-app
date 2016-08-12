module Campaigns
  class NotifyMissingCampaignDaysJob < ActiveJob::Base
    queue_as :campaigns
  
    def perform(date)
      club_data, data = {}, {}

      Club.is_enabled.each do |club|
        unless club_data[club.id] 
          campaigns = club.campaigns.each_with_object({}) do |campaign, h|
            if (missing_days = campaign.missing_days(date: date.to_date)).present?
              h[campaign.id.to_s] = missing_days.map{|d| d.id.to_s}
            end
          end
          club_data[club.id] = campaigns if campaigns.present?
        end
        data = club_data[club.id]
        next if data.blank?
        CampaignNotifier.missing_campaign_days(club_id: club.id, data: data).deliver_later
      end
    end
  end
end