class ChangeAgentColumnRolesDefault < ActiveRecord::Migration
  def up
  	change_column :agents, :roles, :string, :default => ""
  end

  def down
  	change_column :agents, :roles, :string, :default => "--- []"
  end
end
