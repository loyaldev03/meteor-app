class RenameLimitOnDeclineStrategies < ActiveRecord::Migration
  def up
  	rename_column :decline_strategies, :limit, :max_retries
  end

  def down
  	rename_column :decline_strategies, :max_retries, :limit
  end
end
