class RemoveClubIdFromProspects < ActiveRecord::Migration
  def up
    remove_column :prospects, :club_id
  end

  def down
    add_column :prospects, :club_id, :integer, :limit => 8
  end
end
