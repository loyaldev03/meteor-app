class AddEnrollmentInfoToMembers < ActiveRecord::Migration
  def up
    add_column :members, :enrollment_info, :text
  end

  def down
    remove_column :mombers, :enrollment_info, :text
   end
end
