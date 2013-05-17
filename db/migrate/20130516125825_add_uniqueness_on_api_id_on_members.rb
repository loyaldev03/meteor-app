class AddUniquenessOnApiIdOnMembers < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE `members` ADD UNIQUE INDEX `api_id_UNIQUE` (`club_id` ASC, `api_id` ASC);"
  end

  def down
  	execute "ALTER TABLE `members` DROP INDEX `api_id_UNIQUE`;"
  end
end


