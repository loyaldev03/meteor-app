class AddMktClientToClubs < ActiveRecord::Migration
  def up
  	add_column :clubs, :marketing_tool_client, :string
  end

  def down
  	remove_column :clubs, :marketing_tool_client
  end
end
