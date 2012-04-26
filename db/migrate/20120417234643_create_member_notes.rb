class CreateMemberNotes < ActiveRecord::Migration
  def up
    create_table :member_notes, {:id => false} do |t|
      t.integer :member_id, :limit => 8
      t.integer :created_by_id, :limit => 8
      t.text :description
      t.string :note_type
      t.string :communication_type
      t.timestamps
    end
    execute "ALTER TABLE member_notes ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down 
    drop_table :member_notes
  end
end
