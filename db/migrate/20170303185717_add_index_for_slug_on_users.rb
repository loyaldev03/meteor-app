class AddIndexForSlugOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :slug, :string, :limit => 20
    add_index :users, :slug
    change_column :campaigns, :slug, :string, :limit => 20
    add_index :campaigns, :slug
  end
end
