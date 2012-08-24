class ChangeColumnProductNameOnFulfillments < ActiveRecord::Migration
  def up
  	rename_column :fulfillments, :product, :product_sku
  end

  def down
  	rename_column :fulfillments, :product, :product_sku
  end
end
