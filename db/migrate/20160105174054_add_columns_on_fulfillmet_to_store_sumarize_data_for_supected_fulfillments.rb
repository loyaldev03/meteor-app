class AddColumnsOnFulfillmetToStoreSumarizeDataForSupectedFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :email, :string
    add_column :fulfillments, :email_matches_count, :integer
    add_column :fulfillments, :full_name_matches_count, :integer
    add_column :fulfillments, :full_address_matches_count, :integer
    add_column :fulfillments, :full_phone_number_matches_count, :integer
    add_column :fulfillments, :average_match_age, :decimal, :precision => 6, :scale => 2
    add_column :fulfillments, :matching_fulfillments_count, :integer
  end
end
