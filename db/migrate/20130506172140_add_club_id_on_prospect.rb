class AddClubIdOnProspect < ActiveRecord::Migration
  def up
  	add_column :prospects, :club_id, :integer
  end

  def down
  	remove_column :prospects, :club_id
  end
end
