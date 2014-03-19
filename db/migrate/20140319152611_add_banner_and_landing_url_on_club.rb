class AddBannerAndLandingUrlOnClub < ActiveRecord::Migration
  def up
  	add_column :clubs, :member_banner_url, :string
  	add_column :clubs, :member_landing_url, :string
  	add_column :clubs, :non_member_banner_url, :string
  	add_column :clubs, :non_member_landing_url, :string
  end

  def down
  	remove_column :clubs, :member_banner_url
  	remove_column :clubs, :member_landing_url
  	remove_column :clubs, :non_member_banner_url
  	remove_column :clubs, :non_member_landing_url
  end
end
