class AddColumnRequireExternalIdOnClub < ActiveRecord::Migration
  def up
  	add_column :clubs, :requires_external_id, :boolean, :default => false
  end

  def down
    remove_column :clubs, :requires_external_id
  end
end
