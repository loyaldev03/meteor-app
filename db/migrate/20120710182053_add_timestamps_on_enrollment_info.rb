class AddTimestampsOnEnrollmentInfo < ActiveRecord::Migration
  def change
    add_column :enrollment_infos, :created_at, :datetime, :null => false
    add_column :enrollment_infos, :updated_at, :datetime, :null => false
  end
end
