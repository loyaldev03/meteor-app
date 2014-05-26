class AddIndexOnEnrollmentInfosOperationsMembershipsAndMembersTables < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `enrollment_infos` ADD INDEX `index_created_at` (`created_at` DESC);"
    execute "ALTER TABLE `operations` ADD INDEX `index_created_at` (`created_at` DESC);"
    execute "ALTER TABLE `memberships` ADD INDEX `index_created_at` (`created_at` DESC);"
    execute "ALTER TABLE `members` ADD INDEX `index_created_at` (`created_at` DESC);"
  end

  def down
    execute "DROP INDEX index_created_at ON enrollment_infos"
    execute "DROP INDEX index_created_at ON operations"
    execute "DROP INDEX index_created_at ON memberships"
    execute "DROP INDEX index_created_at ON members"
  end
end
