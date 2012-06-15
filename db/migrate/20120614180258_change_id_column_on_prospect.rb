class ChangeIdColumnOnProspect < ActiveRecord::Migration
  def up
    execute "ALTER TABLE prospects MODIFY id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT" 
  	rename_column :prospects, :phone, :phone_number 
  	add_column :prospects, :created_at, :date
  	add_column :prospects, :updated_at, :date
  	change_column_default(:prospects, :joint, false)
  	change_column_default(:members, :joint, false)
  end

  def down
    execute "ALTER TABLE prospects MODIFY id integer UNSIGNED NOT NULL AUTO_INCREMENT" 
  	rename_column :prospects, :phone_number, :phone 
  	remove_column :prospects, :created_at
  	remove_column :prospects, :updated_at
  	change_column_default(:prospects, :joint, true)
  	change_column_default(:members, :joint, true)
  end
end


