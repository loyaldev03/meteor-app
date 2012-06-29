class RenameProspectColumn < ActiveRecord::Migration
  def up
  	rename_column :prospects, :product_id, :product_sku
  	rename_column :prospects, :reporting_code, :marketing_code
  end

  def down
  	rename_column :prospects, :product_sku, :product_id
  	rename_column :prospects, :marketing_code, :reporting_code  	
  end
end
