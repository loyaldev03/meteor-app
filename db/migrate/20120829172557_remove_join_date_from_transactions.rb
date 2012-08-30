class RemoveJoinDateFromTransactions < ActiveRecord::Migration
  def up
    remove_column :transactions, :join_date
  end

  def down
    add_column :transactions, :join_date, :datetime
  end
end
