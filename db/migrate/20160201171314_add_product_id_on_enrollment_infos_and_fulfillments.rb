class AddProductIdOnEnrollmentInfosAndFulfillments < ActiveRecord::Migration
  def up
    add_column :enrollment_infos, :product_id, :integer
    add_column :fulfillments, :product_id, :integer
    
    add_index :enrollment_infos, :product_id
    add_index :fulfillments, :product_id
  end
end
