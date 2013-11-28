class RemoveDescriptionFromAgent < ActiveRecord::Migration
  def up
  	remove_column :agents, :description
  end

  def down
  	add_column :agents, :description, :text
  end
end
