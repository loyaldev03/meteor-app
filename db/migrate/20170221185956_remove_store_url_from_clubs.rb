class RemoveStoreUrlFromClubs < ActiveRecord::Migration
  def change
    remove_column :clubs, :store_url, :string
  end
end
