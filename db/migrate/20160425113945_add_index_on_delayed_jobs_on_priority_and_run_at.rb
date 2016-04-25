class AddIndexOnDelayedJobsOnPriorityAndRunAt < ActiveRecord::Migration
  def change
    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"    
  end
end
