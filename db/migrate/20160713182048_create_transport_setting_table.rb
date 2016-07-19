class CreateTransportSettingTable < ActiveRecord::Migration
  def change
    create_table :transport_settings do |t|
      t.references  :club
      t.integer     :transport, null: false
      t.text        :settings, null: false

      t.timestamps null: false
    end

    add_index :transport_settings, :club_id
    add_index :transport_settings, :transport
    add_index :transport_settings, [:club_id, :transport], unique: true
  end
end
