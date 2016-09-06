class ChangeColumnNamesOnCampaignsRelatedColumns < ActiveRecord::Migration
  def change
    rename_column :memberships, :mega_channel, :utm_campaign
    rename_column :memberships, :source, :utm_source
    rename_column :memberships, :campaign_medium, :utm_medium
    rename_column :memberships, :campaign_medium_version, :utm_content
    rename_column :memberships, :fulfillment_code, :campaign_code
    rename_column :memberships, :marketing_code, :audience
    rename_column :prospects, :mega_channel, :utm_campaign
    rename_column :prospects, :source, :utm_source
    rename_column :prospects, :campaign_medium, :utm_medium
    rename_column :prospects, :campaign_medium_version, :utm_content
    rename_column :prospects, :fulfillment_code, :campaign_code
    rename_column :prospects, :marketing_code, :audience
    rename_column :campaigns, :campaign_medium, :utm_medium
    rename_column :campaigns, :campaign_medium_version, :utm_content
    rename_column :campaigns, :fulfillment_code, :campaign_code
    rename_column :campaigns, :marketing_code, :audience
  end
end
