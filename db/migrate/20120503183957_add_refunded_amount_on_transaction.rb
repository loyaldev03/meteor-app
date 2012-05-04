class AddRefundedAmountOnTransaction < ActiveRecord::Migration
  def up
    add_column :transactions, :refunded_amount, :decimal, :default => 0.0
  end

  def down
    remove_column :transactions, :refunded_amount
  end
end
