class MakeChangesRelatedToStockUnification < ActiveRecord::Migration
  def change
    remove_column :products, :package, :string
    remove_column :products, :cost_center, :string 
    remove_column :fulfillments, :product_package, :string
    
    add_column :clubs, :fulfillment_tracking_prefix, :string, limit: 1
  end
end
