class CreateProducts < ActiveRecord::Migration
  def up
    create_table :products, {:id => false} do |t|
      t.string :name
      t.string :sku
      t.boolean :recurrent, :default => false
      t.integer :stock
      t.integer :weight
      t.integer :club_id, :limit => 8

      t.timestamps
    end
    execute "ALTER TABLE products ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end

  def down
    remove_table :products
  end
end
