class AddIndexOnProspectAndTransactionTables < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `transactions` ADD INDEX `index_created_at` (`created_at` ASC);"
    execute "ALTER TABLE `prospects` ADD INDEX `index_created_at` (`created_at` ASC);"
  end

  def down
  	execute "DROP INDEX index_created_at ON transactions"
  	execute "DROP INDEX index_created_at ON prospects"
  end
end
