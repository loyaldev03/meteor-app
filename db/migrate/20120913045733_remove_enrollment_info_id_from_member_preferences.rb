class RemoveEnrollmentInfoIdFromMemberPreferences < ActiveRecord::Migration
  def up
    change_table :member_preferences do |t|
      t.remove :enrollment_info_id
    end
  end

  def down
    change_table :member_preferences do |t|
      t.integer :enrollment_info_id
    end
  end
end
