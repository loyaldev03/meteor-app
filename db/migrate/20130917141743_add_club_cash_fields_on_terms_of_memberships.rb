class AddClubCashFieldsOnTermsOfMemberships < ActiveRecord::Migration
  def up
  	add_column :terms_of_memberships, :initial_club_cash_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  	add_column :terms_of_memberships, :club_cash_installment_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  	add_column :terms_of_memberships, :skip_first_club_cash, :boolean, :default => false
  end

  def down
  	remove_column :terms_of_memberships, :initial_club_cash_amount
  	remove_column :terms_of_memberships, :club_cash_installment_amount
  	remove_column :terms_of_memberships, :skip_first_club_cash
  end
end
