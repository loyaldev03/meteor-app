class AddClubDetailsToClub < ActiveRecord::Migration
  def change
    add_column :clubs, :cs_email, :string
    add_column :clubs, :privacy_policy_url, :text
  end
end
