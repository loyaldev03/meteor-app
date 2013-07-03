class AddUniquenessOnEmailOnMember < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE `members` ADD UNIQUE INDEX `email_UNIQUE` (`club_id` ASC, `email` ASC);"
	execute "ALTER TABLE `sac_platform_development`.`members` CHANGE COLUMN `email` `email` VARCHAR(255) NOT NULL ;"
  end

  def down
  	execute "ALTER TABLE `members` DROP INDEX `email_UNIQUE`;"
  	execute "ALTER TABLE `members` CHANGE COLUMN `email` `email` VARCHAR(255) NULL  "
  end
end
