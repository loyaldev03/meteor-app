class CreateRoles < ActiveRecord::Migration
  def up
  	create_table :club_roles do |t|
  	  t.belongs_to :agent
      t.belongs_to :club
      t.string :role
      t.timestamps
  	end
  end

  def down
    drop_table :club_roles
  end
end
