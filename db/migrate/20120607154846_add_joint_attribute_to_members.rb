class AddJointAttributeToMembers < ActiveRecord::Migration
  def change
    add_column :members, :joint, :boolean, :default => true
  end
end
