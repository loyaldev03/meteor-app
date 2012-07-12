class ChangeClubCashAmountToInteger < ActiveRecord::Migration
  def up
  	change_column :members, :club_cash_amount, :integer, :limit => 8
  	change_column :club_cash_transactions, :amount, :integer, :limit => 8
  end

  def down
  	change_column :members, :club_cash_amount, :decimal
  	change_column :club_cash_transactions, :amount, :decimal 
  end
end
