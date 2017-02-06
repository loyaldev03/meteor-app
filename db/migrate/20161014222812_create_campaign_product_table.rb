class CreateCampaignProductTable < ActiveRecord::Migration
  def up
    # Because it is BigInt 20 and both columns must have the same type to create the index
    execute "ALTER TABLE products MODIFY COLUMN id int(11) auto_increment;"
    create_table :campaign_products do |t|
      t.belongs_to :campaign, index: true, foreign_key: true
      t.belongs_to :product, index: true, foreign_key: true
      t.string :label
    end
  end

  def down
    drop_table :campaign_products
    execute "ALTER TABLE products MODIFY COLUMN id bigint(20) auto_increment;"
  end
end