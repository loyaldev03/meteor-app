class AddCountToFulfillmentFileTable < ActiveRecord::Migration
  def up
  	add_column :fulfillment_files, :fulfillment_count, :integer, :default => 0
  end

  def down
  	remove_column :fulfillment_files, :fulfillment_count
  end
end
