class AddShippingCostOnFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :shipping_cost, :decimal, precision: 11, scale: 2
  end
end
