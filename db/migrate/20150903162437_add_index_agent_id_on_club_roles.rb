class AddIndexAgentIdOnClubRoles < ActiveRecord::Migration
  def up
    add_index :club_roles, :agent_id
  end

  def down
    remove_index :club_roles, :agent_id
  end
end
