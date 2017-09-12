class AddStoreFieldsOnFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :store_id, :integer
    add_column :fulfillments, :sync_result, :string

    add_index :fulfillments, :store_id
  end
end
