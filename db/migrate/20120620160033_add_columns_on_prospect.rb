class AddColumnsOnProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :club_id, :integer, :limit => 8
  end

  def down
    remove_column :prospects, :club_id
  end
end
