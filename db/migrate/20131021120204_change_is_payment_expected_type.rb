class ChangeIsPaymentExpectedType < ActiveRecord::Migration
  def up
  	change_column :terms_of_memberships, :is_payment_expected, :boolean, :default => true
  end

  def down
  	change_column :terms_of_memberships, :is_payment_expected, :integer
  end
end
