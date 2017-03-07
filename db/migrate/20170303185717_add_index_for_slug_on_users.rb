class AddIndexForSlugOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :slug, :string, :limit => 100
    change_column :campaigns, :slug, :string, :limit => 100
    add_index :users, :slug
    add_index :campaigns, :slug
  end
end
