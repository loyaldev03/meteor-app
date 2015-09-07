class AddIndexAgentIdOnClubRoles < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `club_roles` ADD INDEX `agent_id` (`agent_id` ASC);"
  end

  def down
    execute "DROP INDEX agent_id ON club_roles"
  end
end
