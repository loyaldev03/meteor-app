class CreatePaymentGatewayConfigurations < ActiveRecord::Migration
  def up
    create_table :payment_gateway_configurations, {:id => false} do |t|
      t.string :report_group
      t.string :merchant_key
      t.string :login
      t.string :password
      t.string :mode, :default => 'development'
      t.string :descriptor_name
      t.string :descriptor_phone
      t.string :order_mark
      t.string :gateway
      t.integer :club_id, :limit => 8
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE payment_gateway_configurations ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :payment_gateway_configurations
  end  
end
