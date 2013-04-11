class AddFlagAllowClubCashTransactionOnClub < ActiveRecord::Migration
  def up
  	add_column :clubs, :club_cash_enable, :boolean, :default => true
  end

  def down
  	remove_column :clubs, :club_cash_enable
  end
end
