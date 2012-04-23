class CreateTransactions < ActiveRecord::Migration
  def up
    create_table :transactions, {:id => false} do |t|
      t.string :member_id, :limit => 36
      # payment gateway configuration
      t.integer :payment_gateway_configuration_id, :limit => 8
      t.string :report_group
      t.string :merchant_key
      t.string :login
      t.string :password
      t.string :mode
      t.string :descriptor_name
      t.string :descriptor_phone
      t.string :order_mark
      t.string :gateway
      # credit card information
      t.string :encrypted_number
      t.integer :expire_month
      t.integer :expire_year
      # transaction data
      t.boolean :recurrent, :default => false
      t.string :transaction_type
      t.string :invoice_number
      t.string :first_name
      t.string :last_name
      t.string :home_phone
      t.string :email
      t.string :address_line
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :amount
      # response
      t.integer :decline_strategy_id, :limit => 8
      t.text :response
      t.string :response_code
      t.string :response_result
      t.string :response_transaction_id
      t.string :response_auth_code

      t.timestamps
    end
    execute "ALTER TABLE transactions ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :transactions
  end
end
