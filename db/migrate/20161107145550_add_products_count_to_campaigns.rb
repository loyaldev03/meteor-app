class AddProductsCountToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :products_count, :integer, default: 0
    Campaign.find_each { |c| Campaign.reset_counters(c.id, :campaign_products) }
  end
end
