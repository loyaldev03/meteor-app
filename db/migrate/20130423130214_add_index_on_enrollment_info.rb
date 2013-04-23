class AddIndexOnEnrollmentInfo < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE enrollment_infos ADD INDEX `index_enrollment_info_on_member_id` (`member_id` ASC);"
  end

  def down
  	execute "DROP INDEX index_enrollment_info_on_member_id ON enrollment_infos"
  end
end
