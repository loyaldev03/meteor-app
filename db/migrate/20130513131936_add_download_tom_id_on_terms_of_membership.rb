class AddDownloadTomIdOnTermsOfMembership < ActiveRecord::Migration
  def up
  	add_column :terms_of_memberships, :downgrade_tom_id, :integer
    execute "ALTER TABLE terms_of_memberships MODIFY COLUMN downgrade_tom_id BIGINT(20) DEFAULT NULL;"
  end

  def down
  	remove_column :terms_of_memberships, :downgrade_tom_id
  end
end
