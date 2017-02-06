class AddColumnCampaignIdOnProspectsAndMemberships < ActiveRecord::Migration
  def change
    add_column :prospects, :campaign_id, :integer
    add_column :memberships, :campaign_id, :integer

    add_index :prospects, :campaign_id
    add_index :memberships, :campaign_id
  end
end
