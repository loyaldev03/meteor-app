class CreateCreditCards < ActiveRecord::Migration
  def up
    create_table :credit_cards, {:id => false} do |t|
      t.integer :member_id, :limit => 8
      t.boolean :active, :default => true
      t.string :encrypted_number
      t.integer :expire_month
      t.integer :expire_year
      t.timestamps
    end
    execute "ALTER TABLE credit_cards ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down 
    drop_table :credit_cards
  end
end
