class AddNeedEtSyncOnProspects < ActiveRecord::Migration
  def up
  	add_column :prospects, :need_exact_target_sync, :boolean, :default => false
  end

  def down
  	remove_column :prospects, :need_exact_target_sync
  end
end
