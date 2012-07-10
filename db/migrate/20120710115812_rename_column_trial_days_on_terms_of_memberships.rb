class RenameColumnTrialDaysOnTermsOfMemberships < ActiveRecord::Migration
  def up
  	rename_column :terms_of_memberships, :trial_days, :provisional_days
  end

  def down
  	rename_column :terms_of_memberships, :provisional_days, :trial_days  
  end
end
