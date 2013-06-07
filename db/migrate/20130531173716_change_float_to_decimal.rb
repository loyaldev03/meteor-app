class ChangeFloatToDecimal < ActiveRecord::Migration
  def up
  	change_column :enrollment_infos, :enrollment_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  	change_column :transactions, :amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  	change_column :transactions, :refunded_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  	change_column :terms_of_memberships, :installment_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
  end

  def down
  	change_column :enrollment_infos, :enrollment_amount, :float, :default => 0
  	change_column :transactions, :amount, :float, :default => 0
  	change_column :transactions, :refunded_amount, :float, :default => 0
  	change_column :terms_of_memberships, :installment_amount, :float, :default => 0
  end
end