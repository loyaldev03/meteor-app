class AddIsVisibleToProducts < ActiveRecord::Migration
  def up
  	add_column :products, :is_visible, :boolean, default: true 
  end

  def down
  	remove_column :products, :is_visible
  end
end
