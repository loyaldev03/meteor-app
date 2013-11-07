class CreateMemberAdditionalData < ActiveRecord::Migration
  def change
    create_table :member_additional_data do |t|
      t.integer  "club_id",    :limit => 8
      t.string   "param"
      t.string   "value"
      t.integer  "member_id",  :limit => 8
      t.timestamps
    end
  end
end
