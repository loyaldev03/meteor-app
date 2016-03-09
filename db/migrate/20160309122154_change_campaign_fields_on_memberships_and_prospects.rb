class ChangeCampaignFieldsOnMembershipsAndProspects < ActiveRecord::Migration
  def change
    change_column :memberships, :campaign_medium, :string
    change_column :memberships, :campaign_description, :string
    change_column :memberships, :campaign_medium_version, :string

    change_column :prospects, :campaign_medium, :string
    change_column :prospects, :campaign_description, :string
    change_column :prospects, :campaign_medium_version, :string
  end
end
