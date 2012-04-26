class CreateOperations < ActiveRecord::Migration
  def up
    create_table :operations, {:id => false} do |t|
      t.string :member_id, :limit => 36
      t.text :description
      t.datetime :operation_date
      t.integer :created_by_id
      t.string :status
      # polymorphic . Added manually because resource_id MUST be string (Member ids are string type)
      t.string :resource_id
      t.string :resource_type
      t.timestamps
    end
    execute "ALTER TABLE operations ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :operations
  end
end
