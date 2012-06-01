class AddClubCashAmountToMember < ActiveRecord::Migration
  def change
  	add_column :members, :club_cash_amount, :decimal, :default => 0.0
  end

  def down
  	remove_column :members, :club_cash_amount
  end

end
