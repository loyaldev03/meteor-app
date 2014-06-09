class AddCountToFulfillmentFileTable < ActiveRecord::Migration
  def up
  	add_column :fulfillment_files, :total, :integer, :default => 0
  end

  def down
  	remove_column :fulfillment_files, :total
  end
end
