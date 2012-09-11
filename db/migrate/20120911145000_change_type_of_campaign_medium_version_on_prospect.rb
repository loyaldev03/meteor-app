class ChangeTypeOfCampaignMediumVersionOnProspect < ActiveRecord::Migration
  def up
  	change_column :prospects, :campaign_medium_version, :text
  end

  def down
  	change_column :prospects, :campaign_medium_version, :integer
  end
end
