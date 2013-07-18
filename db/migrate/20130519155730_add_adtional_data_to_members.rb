class AddAdtionalDataToMembers < ActiveRecord::Migration
  def up
  	add_column :members, :additional_data, :text 
  end

  def down
  	remove_column :members, :additional_data 
  end
end
