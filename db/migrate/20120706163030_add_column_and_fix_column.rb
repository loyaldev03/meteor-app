class AddColumnAndFixColumn < ActiveRecord::Migration
  def up
  	rename_column :enrollment_infos, :is_joint, :joint
  end

  def down
  	rename_column :enrollment_infos, :is_joint
  end
end
