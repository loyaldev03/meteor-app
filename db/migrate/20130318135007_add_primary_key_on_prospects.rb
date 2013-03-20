class AddPrimaryKeyOnProspects < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE prospects ADD PRIMARY KEY (uuid)"
  end

  def down
  	execute "ALTER TABLE prospects DROP PRIMARY KEY"
  end
end
