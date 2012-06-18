class ChangeIdColumnOnProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :uuid, :string, :limit => 36
    remove_column :prospects, :id
  	rename_column :prospects, :phone, :phone_number 
  	add_column :prospects, :created_at, :date
  	add_column :prospects, :updated_at, :date
  	change_column_default(:prospects, :joint, false)
  	change_column_default(:members, :joint, false)
  end

  def down
    add_column :prospects, :id, :integer
    remove_column :prospects, :uuid
  	rename_column :prospects, :phone_number, :phone 
  	remove_column :prospects, :created_at
  	remove_column :prospects, :updated_at
  	change_column_default(:prospects, :joint, true)
  	change_column_default(:members, :joint, true)
  end
end


