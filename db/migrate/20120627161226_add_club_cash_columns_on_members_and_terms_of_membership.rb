class AddClubCashColumnsOnMembersAndTermsOfMembership < ActiveRecord::Migration
  def up
  	add_column :members, :club_cash_expire_date, :date
  	add_column :terms_of_memberships, :club_cash_amount, :integer, :default => 0
    # Member.all.each do |m|
    #   m.club_cash_expire_date = m.join_date + 1.year
    #   m.save
    # end
  end

  def down
  	remove_column :members, :club_cash_expire_date
  	remove_column :terms_of_memberships, :club_cash_amount
  end
end
