class AddProductIdOnEnrollmentInfos < ActiveRecord::Migration
  def up
    add_column :enrollment_infos, :product_id, :integer
  end
end
