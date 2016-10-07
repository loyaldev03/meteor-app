class AddLandingUrlOnCampaignsAndStoreUrlOnClub < ActiveRecord::Migration
  def change
    add_column :campaigns, :landing_url, :text
    add_column :clubs, :store_url, :string
  end
end
