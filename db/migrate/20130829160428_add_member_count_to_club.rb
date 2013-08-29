class AddMemberCountToClub < ActiveRecord::Migration
  def up
    add_column :clubs, :members_count, :integer
  end

  def down
    remove_column :clubs, :members_count
  end
end
