class ChangeTypeOfCampaignMediumVersionOnEnrollmentInfo < ActiveRecord::Migration
  def up
  	change_column :enrollment_infos, :campaign_medium_version, :text
  end

  def down
  	change_column :enrollment_infos, :campaign_medium_version, :integer
  end
end
