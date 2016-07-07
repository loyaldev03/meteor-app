class AddIndexesOnStatusOnFulfillments < ActiveRecord::Migration
  def change
    add_index :fulfillments, :status
    add_index :fulfillments, :club_id
  end
end
