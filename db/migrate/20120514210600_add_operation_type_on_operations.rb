class AddOperationTypeOnOperations < ActiveRecord::Migration
  def up
    add_column :operations, :operation_type, :integer
  end

  def down
    remove_column :operations, :operation_type
  end
end
