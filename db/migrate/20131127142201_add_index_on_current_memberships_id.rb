class AddIndexOnCurrentMembershipsId < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `members` ADD INDEX `index_current_membership_id` (`current_membership_id` ASC);"
  end

  def down
    execute "DROP INDEX index_current_membership_id ON members"
  end
end
