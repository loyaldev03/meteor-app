class AddIndexOnResponseTransactionIdOnTransactions < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `transactions` ADD INDEX `index_response_transaction_id` (`response_transaction_id` ASC);"
  end

  def down
    execute "DROP INDEX index_response_transaction_id on transactions"
  end
end
