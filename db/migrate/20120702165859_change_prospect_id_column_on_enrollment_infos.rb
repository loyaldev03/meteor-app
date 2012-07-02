class ChangeProspectIdColumnOnEnrollmentInfos < ActiveRecord::Migration
  def up
  	change_column :enrollment_infos, :prospect_id, :string, :limit => 36
  end

  def down
  	change_column :enrollment_infos, :prospect_id, :integer
  end

end
