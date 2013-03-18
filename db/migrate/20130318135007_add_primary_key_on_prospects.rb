class AddPrimaryKeyOnProspects < ActiveRecord::Migration
  def up
  	execute "ALTER TABLE prospects ADD PRIMARY KEY (uuid)"
  end

  def down
  	execute "ALTER TABLE prospects REMOVE PRIMARY KEY (uuid)"
  end
end
