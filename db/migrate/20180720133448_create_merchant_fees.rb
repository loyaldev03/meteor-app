class CreateMerchantFees < ActiveRecord::Migration
  def change
    create_table :merchant_fees do |t|
      t.string  :name
      t.string  :gateway
      t.string  :transaction_types
      t.decimal :rate,              precision: 4, scale: 4, default: 0.0
      t.decimal :unit_cost,         precision: 12, scale: 4, default: 0.0
      t.boolean :apply_on_decline,  default: true
    end
    
    add_column :transactions, :gateway_cost, :decimal, precision: 11, scale: 4
  end
end
