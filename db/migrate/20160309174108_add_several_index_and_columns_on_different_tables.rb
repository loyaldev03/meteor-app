class AddSeveralIndexAndColumnsOnDifferentTables < ActiveRecord::Migration
  def change
    add_index :transactions, :membership_id
    add_index :products, :sku
    add_index :operations, [:resource_type, :resource_id]

    add_column :transactions, :club_id, :integer
    add_index :transactions, :club_id
  end
end
