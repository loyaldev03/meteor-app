class ChangeDefaultInstallmentTypeOnTermsOfMemberships < ActiveRecord::Migration
  def up
  	change_column :terms_of_memberships, :installment_type, :string, :default => "1.month"
  end

  def down
  	change_column :terms_of_memberships, :installment_type, :string, :default => "30.days"
  end
end
