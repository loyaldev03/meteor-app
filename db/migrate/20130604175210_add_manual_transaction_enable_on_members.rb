class AddManualTransactionEnableOnMembers < ActiveRecord::Migration
  def up
  	add_column :members, :manual_payment, :boolean, :default => false
  end

  def down
  	remove_column :members, :manual_payment
  end
end
