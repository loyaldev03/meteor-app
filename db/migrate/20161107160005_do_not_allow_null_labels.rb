class DoNotAllowNullLabels < ActiveRecord::Migration
  def change
    change_column_null :campaign_products, :label, false
  end
end
