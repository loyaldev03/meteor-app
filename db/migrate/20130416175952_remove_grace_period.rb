class RemoveGracePeriod < ActiveRecord::Migration
  def up
  	remove_column :terms_of_memberships, :grace_period
  end

  def down
  	add_column :terms_of_memberships, :grace_period, :integer
  end
end
