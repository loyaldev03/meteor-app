class RemoveEnrolllmentInfoFromTransactions < ActiveRecord::Migration
  def up
    remove_column :transactions, :enrollment_info_id
    add_column :members, :cohort, :string
  end

  def down
    add_column :transactions, :enrollment_info_id, :integer
    remove_column :members, :cohort
  end
end
