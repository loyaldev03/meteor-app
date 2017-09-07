class AddCreateRemoteUserInBackgroundOnCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :create_remote_user_in_background, :boolean, default: false
  end
end
