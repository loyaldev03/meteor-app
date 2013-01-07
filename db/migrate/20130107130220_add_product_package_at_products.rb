class AddProductPackageAtProducts < ActiveRecord::Migration
  def up
    add_column :products, :package, :string
    Product.all.each do |p|
      p.package = p.sku
      p.save
    end
    add_column :fulfillments, :product_package, :string
  end

  def down
    remove_column :products, :package
    remove_column :fulfillments, :product_package
  end
end
