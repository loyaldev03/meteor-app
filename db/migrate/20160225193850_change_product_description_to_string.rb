class ChangeProductDescriptionToString < ActiveRecord::Migration
  def change
    change_column :memberships, :product_description, :string
    change_column :prospects, :product_description, :string
  end
end
