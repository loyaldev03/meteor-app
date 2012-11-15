class AddPardotIdToMembers < ActiveRecord::Migration
  def up
    add_column :members, :pardot_id, :string
    add_column :members, :pardot_last_synced_at, :datetime
    add_column :members, :pardot_synced_status, :string, :default => 'not_synced'
    add_column :members, :pardot_last_sync_error, :string
    add_column :members, :pardot_last_sync_error_at, :datetime
    remove_column :members, :joint
  end
  def down
    remove_column :members, :pardot_id
    remove_column :members, :pardot_last_synced_at
    remove_column :members, :pardot_synced_status
    remove_column :members, :pardot_last_sync_error
    remove_column :members, :pardot_last_sync_error_at
    add_column :members, :joint, :boolean
  end
end
