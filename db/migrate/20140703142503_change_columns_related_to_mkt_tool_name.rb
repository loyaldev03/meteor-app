class ChangeColumnsRelatedToMktToolName < ActiveRecord::Migration
  def up
  	remove_column :members, :pardot_id
  	remove_column :members, :pardot_last_synced_at
    remove_column :members, :pardot_synced_status
  	remove_column :members, :pardot_last_sync_error
  	remove_column :members, :pardot_last_sync_error_at
  	add_column :members, :marketing_client_id, :string
  	rename_column :members, :exact_target_last_synced_at, :marketing_client_last_synced_at
  	rename_column :members, :exact_target_synced_status, :marketing_client_synced_status
  	rename_column :members, :exact_target_last_sync_error, :marketing_client_last_sync_error
  	rename_column :members, :exact_target_last_sync_error_at, :marketing_client_last_sync_error_at
  	rename_column :members, :need_exact_target_sync, :need_sync_to_marketing_client
  	rename_column :prospects, :exact_target_sync_result, :marketing_client_sync_result
  	rename_column :prospects, :need_exact_target_sync, :need_sync_to_marketing_client
  end

  def down
  	add_column :members, :pardot_id, :string
  	add_column :members, :pardot_last_synced_at, :datetime
  	add_column :members, :pardot_synced_status, :string
    add_column :members, :pardot_last_sync_error, :string
  	add_column :members, :pardot_last_sync_error_at, :datetime
  	remove_column :members, :marketing_client_id
   	rename_column :members, :marketing_client_last_synced_at, :exact_target_last_synced_at
  	rename_column :members, :marketing_client_synced_status, :exact_target_synced_status
  	rename_column :members, :marketing_client_last_sync_error, :exact_target_last_sync_error
  	rename_column :members, :marketing_client_last_sync_error_at, :exact_target_last_sync_error_at
  	rename_column :members, :need_sync_to_marketing_client, :need_exact_target_sync
  	rename_column :prospects, :marketing_client_sync_result, :exact_target_sync_result
  	rename_column :prospects, :need_sync_to_marketing_client, :need_exact_target_sync
  end
end