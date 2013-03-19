class AddMissingKeys < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE transactions ADD PRIMARY KEY (uuid)"
  end

  def down
  	execute "ALTER TABLE transactions DROP PRIMARY KEY"
  end
end
