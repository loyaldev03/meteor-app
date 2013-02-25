class ChangeClubCashFormat < ActiveRecord::Migration
  def up
  	change_column :members, :club_cash_amount, :decimal, :precision => 11, :scale => 2
  	change_column :club_cash_transactions, :amount, :decimal, :precision => 11, :scale => 2
  	change_column :terms_of_memberships, :club_cash_amount, :decimal, :precision => 11, :scale => 2
  end

  def down
  	change_column :members, :club_cash_amount, :float
  	change_column :club_cash_transactions, :club_cash_amount, :float
  	change_column :terms_of_memberships, :club_cash_amount, :float
  end
end
