class ChangeClubCashToFloatOnTermOfMembership < ActiveRecord::Migration
  def up
  	change_column :terms_of_memberships, :club_cash_amount, :float
  end

  def down
  	change_column :terms_of_memberships, :club_cash_amount, :integer
  end
end
