class AddColumnTrackingCodeOnFulfillment < ActiveRecord::Migration
  def up
  	add_column :fulfillments, :tracking_code, :string
  end

  def down
  	remove_column :fulfillments, :tracking_code
  end
end
