class AddPositionToCampaignProductsTable < ActiveRecord::Migration
  def change
    add_column :campaign_products, :position, :integer
  end
end
