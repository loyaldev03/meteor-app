class AddDefaultToInstallmentPeriodOnTermsOfMembership < ActiveRecord::Migration
  def up
  	change_column :terms_of_memberships, :installment_period, :integer, :default => 1
  end

  def down
  	change_column :terms_of_memberships, :installment_period, :integer, :default => nil
  end
end
