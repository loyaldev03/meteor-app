class AddIndexesOnFulfillmentTable < ActiveRecord::Migration
  def change
    add_index :fulfillments, :email
    add_index :fulfillments, :full_name
    add_index :fulfillments, :full_address
    add_index :fulfillments, :full_phone_number
  end
end
