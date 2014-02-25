class AddNeedEtSyncOnMembers < ActiveRecord::Migration
  def up
  	add_column :members, :need_exact_target_sync, :boolean, :default => false
  end

  def down
  	remove_column :members, :need_exact_target_sync
  end
end
