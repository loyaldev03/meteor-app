class AddPardotIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :pardot_id, :string
    add_column :members, :pardot_last_synced_at, :datetime
    add_column :members, :pardot_synced_status, :string, :default => 'not_synced'
    add_column :members, :pardot_last_sync_error, :string
    add_column :members, :pardot_last_sync_error_at, :datetime
  end
end
