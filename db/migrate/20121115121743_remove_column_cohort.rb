class RemoveColumnCohort < ActiveRecord::Migration
  def up
    remove_column :transactions, :cohort
    remove_column :prospects, :cohort
    remove_column :operations, :cohort
    remove_column :memberships, :cohort
    remove_column :members, :cohort
    remove_column :enrollment_infos, :cohort
  end

  def down
    add_column :transactions, :cohort, :string
    add_column :prospects, :cohort, :string
    add_column :operations, :cohort, :string
    add_column :memberships, :cohort, :string
    add_column :members, :cohort, :string
    add_column :enrollment_infos, :cohort, :string
  end
end
