class CreateClubs < ActiveRecord::Migration
  def up
    create_table :clubs, {:id => false} do |t|
      t.text :description
      t.string :name
      t.integer :partner_id, :limit => 8
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE clubs ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
    add_column :domains, :club_id, :integer, :limit => 8
  end
  def down
    drop_table :clubs
  end
end
