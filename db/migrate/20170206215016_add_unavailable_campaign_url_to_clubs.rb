class AddUnavailableCampaignUrlToClubs < ActiveRecord::Migration
  def change
    add_column :clubs, :unavailable_campaign_url, :text
  end
end
