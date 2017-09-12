class RemoveLowStockAlertsColumnsFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :alert_on_low_stock, :boolean, default: false
    remove_column :products, :low_stock_alerted, :boolean, default: false
  end
end
