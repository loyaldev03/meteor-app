class AmountColumnsDoesNotSupportDecimals < ActiveRecord::Migration
  def up
    change_column :terms_of_memberships, :installment_amount, :float
    change_column :transactions, :amount, :float
  end

  def down
    change_column :terms_of_memberships, :installment_amount, :decimal
    change_column :transactions, :amount, :decimal
  end
end
