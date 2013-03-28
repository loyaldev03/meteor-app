class NormalizeIntColumnsToBigint < ActiveRecord::Migration
  def up
    change_column :club_roles, :club_id, :bigint
    change_column :fulfillment_files_fulfillments, :fulfillment_id, :bigint
    execute "ALTER TABLE communications CHANGE COLUMN id id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE memberships CHANGE COLUMN id id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT;"
  end

  def down
    change_column :club_roles, :club_id, :integer
    change_column :fulfillment_files_fulfillments, :fulfillment_id, :integer
    execute "ALTER TABLE communications CHANGE COLUMN id id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT;"
    execute "ALTER TABLE memberships CHANGE COLUMN id id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT;"
  end
end
