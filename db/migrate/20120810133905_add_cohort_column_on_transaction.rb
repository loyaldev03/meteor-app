class AddCohortColumnOnTransaction < ActiveRecord::Migration
  def up
  	add_column :transactions, :enrollment_info_id, :integer
  	add_column :transactions, :join_date, :datetime
  	add_column :transactions, :cohort, :string
  end

  def down
  	remove_column :transactions, :cohort
  end
end
