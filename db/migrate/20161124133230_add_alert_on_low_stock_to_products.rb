class AddAlertOnLowStockToProducts < ActiveRecord::Migration
  def change
    add_column :products, :alert_on_low_stock, :boolean, default: false
    add_column :products, :low_stock_alerted, :boolean, default: false
  end
end
