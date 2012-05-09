class AddBlacklistToMember < ActiveRecord::Migration
  def up
    add_column :members, :blacklisted, :boolean, :default => 0
  end

    def down
    remove_column :members, :blacklisted
  end
end
