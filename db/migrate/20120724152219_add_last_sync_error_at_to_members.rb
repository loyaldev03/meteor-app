class AddLastSyncErrorAtToMembers < ActiveRecord::Migration
  def change
  	change_table :members do |t|
      t.datetime :last_sync_error_at
  	end
  end
end
