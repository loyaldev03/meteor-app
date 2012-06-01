class AddClubCashAmountToMember < ActiveRecord::Migration
  def change
  	add_column :members, :club_cash_amount, :decimal
  end

  def down
  	remove_column :members, :club_cash_amount
  end

end
