class AddCohortIntoEnrollmentInfo < ActiveRecord::Migration
  def up
    add_column :enrollment_infos, :cohort, :string
  end

  def down
    remove_column :enrollment_infos, :cohort
  end
end
