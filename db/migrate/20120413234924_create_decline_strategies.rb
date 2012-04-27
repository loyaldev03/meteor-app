class CreateDeclineStrategies < ActiveRecord::Migration
  def up
    create_table :decline_strategies, {:id => false} do |t|
      t.string :gateway
      t.string :installment_type, :default => 'monthly'
      t.string :credit_card_type, :default => 'all'
      t.string :response_code
      t.integer :limit, :default => 0
      t.integer :days, :default => 0
      t.string :decline_type, :default => 'soft'
      t.text :notes
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE decline_strategies ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :decline_strategies
  end
end
