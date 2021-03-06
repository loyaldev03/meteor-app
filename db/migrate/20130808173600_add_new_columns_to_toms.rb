class AddNewColumnsToToms < ActiveRecord::Migration
	def up
		add_column :terms_of_memberships, :initial_fee, :decimal, :precision => 5, :scale => 2
		add_column :terms_of_memberships, :trial_period_amount, :decimal, :precision => 5, :scale => 2
		add_column :terms_of_memberships, :is_payment_expected, :integer
		add_column :terms_of_memberships, :installment_period, :integer
		add_column :terms_of_memberships, :subscription_limits, :integer
		add_column :terms_of_memberships, :if_cannot_bill, :string
		add_column :terms_of_memberships, :suspension_period, :integer
		add_column :terms_of_memberships, :upgrade_tom_id, :integer
		add_column :terms_of_memberships, :upgrade_tom_period, :integer
	end

	def down
		remove_column :terms_of_memberships, :initial_fee
		remove_column :terms_of_memberships, :trial_period_amount
		remove_column :terms_of_memberships, :is_payment_expected
		remove_column :terms_of_memberships, :installment_period
		remove_column :terms_of_memberships, :subscription_limits
		remove_column :terms_of_memberships, :if_cannot_bill
		remove_column :terms_of_memberships, :suspension_period
		remove_column :terms_of_memberships, :upgrade_tom_id
		remove_column :terms_of_memberships, :upgrade_tom_period
	end
end