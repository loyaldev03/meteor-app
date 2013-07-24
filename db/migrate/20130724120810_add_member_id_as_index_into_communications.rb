class AddMemberIdAsIndexIntoCommunications < ActiveRecord::Migration
  def up
    add_index :communications, :member_id
  end

  def down
    remove_index :communications, :member_id
  end
end
