class AddClubIdOnOperations < ActiveRecord::Migration
  def change
    add_column :operations, :club_id, :integer
  end
end
