class RemoveModeFromTransactions < ActiveRecord::Migration
  def up
  	remove_column :transactions, :mode
  end

  def down
  	add_column :transactions, :mode, :string
  end
end
