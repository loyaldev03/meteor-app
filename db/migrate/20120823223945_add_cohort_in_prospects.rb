class AddCohortInProspects < ActiveRecord::Migration
  def up
    add_column :prospects, :cohort, :string
  end

  def down
    remove_column :prospects, :cohort, :string
  end
end
