class AddTitleToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :title, :string
    Campaign.update_all('title = name')
  end
end
