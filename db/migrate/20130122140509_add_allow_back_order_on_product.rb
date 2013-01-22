class AddAllowBackOrderOnProduct < ActiveRecord::Migration
  def up
  	add_column :products, :allow_backorder, :boolean, :default => false
  end

  def down
  	remove_column :products, :allow_backorder
  end
end
