class AddMaintenanceModeOnClub < ActiveRecord::Migration
  def change
    add_column :clubs, :maintenance_mode, :boolean, default: false
  end
end
