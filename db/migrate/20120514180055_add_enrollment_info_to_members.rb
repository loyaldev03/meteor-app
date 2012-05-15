class AddEnrollmentInfoToMembers < ActiveRecord::Migration
  def up
    add_column :members, :enrollment_info, :text
  end

  def down
    remove_column :members, :enrollment_info
   end
end
