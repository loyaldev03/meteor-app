class RemoveUnusedUuid < ActiveRecord::Migration
  def up
  	remove_column :member_preferences, :uuid
  	remove_column :transactions, :uuid
  end

  def down
  	add_column :member_preferences, :uuid, :string, :limit => 36
  	add_column :transactions, :uuid, :string, :limit => 36
  end
end
