module Campaigns
  class NotifyCampaignDaysWithErrorJob < ActiveJob::Base
    queue_as :campaigns

    def perform
      campaign_days_list = CampaignDay.joins(:campaign).unauthorized.pluck(:campaign_id).uniq
      if campaign_days_list.any?
        Campaign.includes(:club).where(id: campaign_days_list).
          group_by{ |campaign| campaign.club_id }.
          each do |club_id, campaigns|
            CampaignNotifier.invalid_credentials(club_id: club_id, campaign_ids: campaigns.collect(&:id)).deliver_later
          end
      end

      campaign_days_list = CampaignDay.joins(:campaign).invalid_campaign.pluck(:campaign_id).uniq
      if campaign_days_list.any?
        Campaign.includes(:club).where(id: campaign_days_list).
          group_by{ |campaign| campaign.club_id }.
          each do |club_id, campaigns|
            CampaignNotifier.invalid_campaign(club_id: club_id, campaign_ids: campaigns.collect(&:id)).deliver_later
          end
      end
    end

  end
end