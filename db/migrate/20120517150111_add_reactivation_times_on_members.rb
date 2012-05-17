class AddReactivationTimesOnMembers < ActiveRecord::Migration
  def up
    add_column :members, :reactivation_times, :integer, :default => 0
  end

  def down
    remove_column :members, :reactivation_times
  end
end
