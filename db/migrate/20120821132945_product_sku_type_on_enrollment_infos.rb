class ProductSkuTypeOnEnrollmentInfos < ActiveRecord::Migration
  def up
  	change_column :enrollment_infos, :product_sku, :text
  end

  def down
  	change_column :enrollment_infos, :product_sku, :string, :limit => 255
  end
end
