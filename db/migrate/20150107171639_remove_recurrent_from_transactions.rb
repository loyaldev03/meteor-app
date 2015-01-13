class RemoveRecurrentFromTransactions < ActiveRecord::Migration
  def up
  	remove_column :transactions, :recurrent
  end

  def down
  	add_column :transactions, :recurrent, :boolean, default: false
  end
end
