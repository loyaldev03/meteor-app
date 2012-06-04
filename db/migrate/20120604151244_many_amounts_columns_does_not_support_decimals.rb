class ManyAmountsColumnsDoesNotSupportDecimals < ActiveRecord::Migration
  def up
    change_column :club_cash_transactions, :amount, :float
    change_column :transactions, :refunded_amount, :float
    change_column :members, :club_cash_amount, :float
  end

  def down
    change_column :club_cash_transactions, :amount, :decimal
    change_column :transactions, :refunded_amount, :decimal
    change_column :members, :club_cash_amount, :decimal
  end
end
