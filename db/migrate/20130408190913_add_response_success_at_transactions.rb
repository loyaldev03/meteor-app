class AddResponseSuccessAtTransactions < ActiveRecord::Migration
  def up
    add_column :transactions, :success, :boolean, :default => false
  end

  def down
    remove_column :transactions, :success
  end
end
