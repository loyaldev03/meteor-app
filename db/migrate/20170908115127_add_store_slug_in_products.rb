class AddStoreSlugInProducts < ActiveRecord::Migration
  def change
    add_column :products, :store_slug, :string
  end
end
