class ChangeInstallmentPeriodToDecimal < ActiveRecord::Migration
  def up
  	change_column :terms_of_memberships, :installment_period, :decimal, :precision => 11, :scale => 2
  end

  def down
  	change_column :terms_of_memberships, :installment_period, :integer
  end
end
