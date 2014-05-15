class ChangeIdColumnOnTransactionsAndProspects < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE transactions CHANGE COLUMN uuid uuid VARCHAR(36) NULL, DROP PRIMARY KEY"
  	execute "ALTER TABLE transactions ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY"
   	execute "ALTER TABLE prospects CHANGE COLUMN uuid uuid VARCHAR(36) NULL, DROP PRIMARY KEY"
  	execute "ALTER TABLE prospects ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY"
  end

  def down
	execute "ALTER TABLE transactions CHANGE COLUMN id id BIGINT(20) NULL, DROP PRIMARY KEY"  
  execute "ALTER TABLE transactions CHANGE COLUMN uuid uuid VARCHAR(36) NOT NULL, ADD PRIMARY KEY (`uuid`)"
  remove_column :transactions, :id
  execute "ALTER TABLE prospects CHANGE COLUMN id id BIGINT(20) NULL, DROP PRIMARY KEY"  
  execute "ALTER TABLE prospects CHANGE COLUMN uuid uuid VARCHAR(36) NOT NULL, ADD PRIMARY KEY (`uuid`)"
  remove_column :prospects, :id
  end
end
