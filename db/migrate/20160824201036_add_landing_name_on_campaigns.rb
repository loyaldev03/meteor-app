class AddLandingNameOnCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :landing_name, :string
  end
end
