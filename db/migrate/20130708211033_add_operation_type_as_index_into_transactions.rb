class AddOperationTypeAsIndexIntoTransactions < ActiveRecord::Migration
  def self.up
    add_index :transactions, :operation_type
  end

  def self.down
    remove_index :transactions, :operation_type
  end
end
