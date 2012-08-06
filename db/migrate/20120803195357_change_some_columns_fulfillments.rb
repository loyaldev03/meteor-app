class ChangeSomeColumnsFulfillments < ActiveRecord::Migration
  def up
  	remove_column :fulfillments, :delivered_at
  	add_column :fulfillments, :recurrent, :boolean
  end

  def down
  	add_column :fulfillments, :delivered_at, :datetime
  	remove_column :fulfillments, :recurrent
  end
end
