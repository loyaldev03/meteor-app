class RemoveIndexMembersOnClubId < ActiveRecord::Migration
  def up
    remove_index :users, name: :index_members_on_club_id
  end
  def down
    add_index :users, :club_id, name: "index_members_on_club_id"
  end
end
