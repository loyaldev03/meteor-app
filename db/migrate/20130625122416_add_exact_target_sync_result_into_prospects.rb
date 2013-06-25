class AddExactTargetSyncResultIntoProspects < ActiveRecord::Migration
  def up
    add_column :prospects, :exact_target_sync_result, :string
  end

  def down
    remove_column :prospects, :exact_target_sync_result
  end
end
