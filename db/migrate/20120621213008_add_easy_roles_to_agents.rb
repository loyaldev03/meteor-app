class AddEasyRolesToAgents < ActiveRecord::Migration
  def self.up
    add_column :agents, :roles, :string, :default => "--- []"
  end

  def self.down
    remove_column :agents, :roles
  end
end
