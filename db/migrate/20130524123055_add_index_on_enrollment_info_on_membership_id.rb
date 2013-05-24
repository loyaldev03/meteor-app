class AddIndexOnEnrollmentInfoOnMembershipId < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE `enrollment_infos` ADD INDEX `index_membership_id` (`membership_id` ASC);"
  end

  def down
  	execute "DROP INDEX index_membership_id ON enrollment_infos"
  end
end