class ChangeProductSkuTypeOnMemberships < ActiveRecord::Migration
  def change
    change_column :memberships, :product_sku, :string
  end
end
