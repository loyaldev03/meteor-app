class AddDownloadTomIdOnTermsOfMembership < ActiveRecord::Migration
  def up
    execute "ALTER TABLE terms_of_memberships ADD COLUMN downgrade_tom_id BIGINT(20);"
  end

  def down
  	remove_column :terms_of_memberships, :downgrade_tom_id
  end
end
