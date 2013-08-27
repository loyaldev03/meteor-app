class AddAvoidSyncOnProspect < ActiveRecord::Migration
  def up
  	add_column :prospects, :allow_sync, :boolean, :default => true
  end

  def down
  	remove_column :prospects, :allow_sync
  end
end
