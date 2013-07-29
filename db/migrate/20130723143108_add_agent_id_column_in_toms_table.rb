class AddAgentIdColumnInTomsTable < ActiveRecord::Migration
  def up
    add_column :terms_of_memberships, :agent_id, :integer
  end

  def down
    remove_column :terms_of_memberships, :agent_id
  end
end
