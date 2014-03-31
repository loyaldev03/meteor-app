class AddParentMembershipAndCurrentJoinDate < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE memberships ADD COLUMN parent_membership_id BIGINT(20);"
    add_column :members, :current_join_date, :datetime
  end

  def down
  	remove_column :memberships, :parent_membership_id
    remove_column :members, :current_join_date
  end
end
