class AddDrupalRoleOnTermsOfMemberships < ActiveRecord::Migration
  def up
  	add_column :terms_of_memberships, :drupal_role, :string, :default => "[91284557]"
  end

  def down
  	remove_column :terms_of_memberships, :drupal_role
  end
end
