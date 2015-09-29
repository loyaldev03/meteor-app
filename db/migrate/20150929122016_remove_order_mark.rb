class RemoveOrderMark < ActiveRecord::Migration
  def change
    remove_column :payment_gateway_configurations, :order_mark
    remove_column :transactions, :order_mark
  end
end
