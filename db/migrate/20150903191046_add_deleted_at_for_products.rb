class AddDeletedAtForProducts < ActiveRecord::Migration
  def up
    add_column :products, :deleted_at, :datetime
    execute "DROP INDEX sku_per_club_uniqueness ON products;"
  end

  def down
    remove_column :products, :deleted_at
    execute "ALTER TABLE `products` ADD UNIQUE INDEX `sku_per_club_uniqueness` (`sku` ASC, `club_id` ASC);"
  end
end
