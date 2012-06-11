class RemoveDescriptionFromMember < ActiveRecord::Migration
  def up
  	remove_column :members, :description
  end

  def down
    add_column :members, :description, :text
  end
end
