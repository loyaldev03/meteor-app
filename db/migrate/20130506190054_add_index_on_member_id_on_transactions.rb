class AddIndexOnMemberIdOnTransactions < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE transactions ADD INDEX `index_transactions_on_member_id` (`member_id` ASC);"
  end

  def down
  	execute "DROP INDEX `index_transactions_on_member_id` ON transactions"
  end
end
