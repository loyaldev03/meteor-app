class AddSocialLinksToClubs < ActiveRecord::Migration
  def change
    add_column :clubs, :twitter_url, :string
    add_column :clubs, :facebook_url, :string
  end
end
