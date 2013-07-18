class AddMarketingToolAttributesOnClub < ActiveRecord::Migration
  def up
    add_column :clubs, :marketing_tool_attributes, :text
    remove_column :clubs, :pardot_email
    remove_column :clubs, :pardot_password
    remove_column :clubs, :pardot_user_key
    add_column :members, "exact_target_last_synced_at", :datetime
    add_column :members, "exact_target_synced_status", :string,                   :default => "not_synced"
    add_column :members, "exact_target_last_sync_error", :string
    add_column :members, "exact_target_last_sync_error_at", :datetime
  end

  def down
    remove_column :clubs, :marketing_tool_attributes
    add_column :clubs, :pardot_email
    add_column :clubs, :pardot_password
    add_column :clubs, :pardot_user_key
    remove_column :members, "exact_target_last_synced_at"
    remove_column :members, "exact_target_synced_status"
    remove_column :members, "exact_target_last_sync_error"
    remove_column :members, "exact_target_last_sync_error_at"
  end
end
