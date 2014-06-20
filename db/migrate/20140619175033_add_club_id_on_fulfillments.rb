class AddClubIdOnFulfillments < ActiveRecord::Migration
  def up
  	add_column :fulfillments, :club_id, :bigint
  end

  def down
  	remove_column :fulfillments, :club_id
  end
end
