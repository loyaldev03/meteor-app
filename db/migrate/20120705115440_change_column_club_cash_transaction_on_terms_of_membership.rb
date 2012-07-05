class ChangeColumnClubCashTransactionOnTermsOfMembership < ActiveRecord::Migration
  def up
  	change_column_default(:terms_of_memberships,:club_cash_amount,0)   	
  end

  def down
  	change_column_default(:terms_of_memberships,:club_cash_amount,nil)   	
  end
end
