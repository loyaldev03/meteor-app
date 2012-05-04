class CreateEnumerations < ActiveRecord::Migration
  def up
    create_table :enumerations do |t|
      t.string :type
      t.string :name
      t.integer :position
      t.integer :club_id, :limit => 8
      t.boolean :visible, :default => true
      t.datetime :deleted_at
      t.timestamps
    end
  end
  def down
    drop_table :enumerations
  end
end
