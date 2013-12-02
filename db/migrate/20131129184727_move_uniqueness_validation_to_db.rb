class MoveUniquenessValidationToDb < ActiveRecord::Migration
  def up
	execute "ALTER TABLE `products` ADD UNIQUE INDEX `sku_per_club_uniqueness` (`sku` ASC, `club_id` ASC);"
  end

  def down
  	execute "DROP INDEX sku_per_club_uniqueness ON products;"
  end
end
