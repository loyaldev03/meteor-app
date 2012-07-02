class AddProspectIdToEnrollmentInfos < ActiveRecord::Migration
  def up
  	add_column :enrollment_infos, :prospect_id, :integer
  end

  def down
  	remove_column :enrollment_infos, :prospect_id
  end

end
