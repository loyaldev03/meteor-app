class AddBillingEnableFieldToClub < ActiveRecord::Migration
  def up
  	add_column :clubs, :billing_enable, :boolean, :default => true
  end

  def down
  	remove_column :clubs, :billing_enable
  end
end
