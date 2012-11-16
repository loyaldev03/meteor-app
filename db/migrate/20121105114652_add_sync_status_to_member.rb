class AddSyncStatusToMember < ActiveRecord::Migration
  def up
  	add_column :members, :sync_status, :string, :default => "not_synced"
  end

  def down
  	remove_column :members, :sync_status
  end
end
