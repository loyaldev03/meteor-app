class ChangeSpentOnCampaignDays < ActiveRecord::Migration
  def change
    change_column :campaign_days, :spent, :decimal, precision: 10, scale: 2
  end
end
