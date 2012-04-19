class CreateOperations < ActiveRecord::Migration
  def up
    create_table :operations, {:id => false} do |t|
      t.text :description
      t.datetime :operation_date
      t.integer :created_by_id
      t.string :status
      t.references :resource, :polymorphic => true
      t.timestamps
    end
    execute "ALTER TABLE operations ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
  end
end
