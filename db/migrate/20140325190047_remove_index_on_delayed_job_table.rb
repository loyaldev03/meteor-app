class RemoveIndexOnDelayedJobTable < ActiveRecord::Migration
  def up
  	execute "DROP INDEX delayed_jobs_priority ON delayed_jobs"
  end

  def down
  	add_index "delayed_job", ["priority", "run_at"], :name => "delayed_jobs_priority"
  end
end