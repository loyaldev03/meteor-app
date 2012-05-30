class AddSyncDataToMember < ActiveRecord::Migration
  def change
    change_table :members do |t|
      t.datetime :last_synced_at
      t.text :last_sync_error
    end
  end
end
