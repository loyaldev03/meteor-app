class AddCohortIntoOperationsTabel < ActiveRecord::Migration
  def up
    add_column :operations, :cohort, :string
  end

  def down
    remove_column :operations, :cohort
  end
end
