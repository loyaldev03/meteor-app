class AddIndexesOnStatusOnFulfillments < ActiveRecord::Migration
  def change
    add_index :fulfillments, :status
  end
end
