class CreateEnrollmentPreferences < ActiveRecord::Migration
  def change
    create_table :member_preferences, :id => false do |t|
      t.string  :uuid, :limit => 36
      t.integer :enrollment_info_id, :limit => 8
      t.integer :club_id, :limit => 8
      t.string :member_id, :limit => 36
      t.string :param
      t.string :value
      t.timestamps
    end
    add_column :members, :preferences, :text
  end
end
