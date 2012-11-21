class ChangeClubCashAmountFromIntegerToFloat < ActiveRecord::Migration
  def up
  	change_column :club_cash_transactions, :amount, :float
  	change_column :members, :club_cash_amount, :float
  end

  def down
  	change_column :club_cash_transactions, :amount, :integer
  	change_column :members, :club_cash_amount, :integer
  end
end
