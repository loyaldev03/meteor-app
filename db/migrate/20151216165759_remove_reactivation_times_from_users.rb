class RemoveReactivationTimesFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :reactivation_times, :integer
  end
end
