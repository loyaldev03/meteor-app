class AddIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, [:need_sync_to_marketing_client, :club_id]
  end
end
