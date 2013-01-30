class AddCostCenterToProduct < ActiveRecord::Migration
  def up
  	add_column :products, :cost_center, :string
  end 

  def down
  	remove_column :products, :cost_center
  end
end
