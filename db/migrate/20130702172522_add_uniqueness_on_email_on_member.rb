class AddUniquenessOnEmailOnMember < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE `members` ADD UNIQUE INDEX `email_UNIQUE` (`club_id` ASC, `email` ASC);"
	execute "ALTER TABLE `members` CHANGE COLUMN `email` `email` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL;"
  end

  def down
  	execute "ALTER TABLE `members` DROP INDEX `email_UNIQUE`;"
  	execute "ALTER TABLE `members` CHANGE COLUMN `email` `email` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL  "
  end
end
