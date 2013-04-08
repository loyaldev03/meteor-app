class FixTypeOnRelationColumns < ActiveRecord::Migration
  def up
    execute "ALTER TABLE fulfillment_files MODIFY COLUMN club_id BIGINT(20) DEFAULT NULL;"
  	change_column :member_notes, :created_by_id, :integer
  end

  def down
    execute "ALTER TABLE fulfillment_files MODIFY COLUMN club_id INTEGER"
    execute "ALTER TABLE member_notes MODIFY COLUMN created_by_id BIGINT(20) DEFAULT NULL;"
  end
end
