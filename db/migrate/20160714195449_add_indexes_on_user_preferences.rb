class AddIndexesOnUserPreferences < ActiveRecord::Migration
  def change
    add_index :user_preferences, [:user_id, :club_id, :param]
  end
end
