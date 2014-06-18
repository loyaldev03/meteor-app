# Requested in: https://www.pivotaltracker.com/s/projects/840477/stories/57147576

class RemoveClubCashColumns < ActiveRecord::Migration
  def up
  	remove_column :terms_of_memberships, :club_cash_amount
  	remove_column :terms_of_memberships, :quota
  	remove_column :memberships, :quota
  end

  def down
  	add_column :terms_of_memberships, :club_cash_amount, :decimal, :precision => 11, :scale => 2
  	add_column :terms_of_memberships, :quota, :integer
  	add_column :memberships, :quota, :integer
  end
end
