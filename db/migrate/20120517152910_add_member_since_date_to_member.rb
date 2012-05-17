class AddMemberSinceDateToMember < ActiveRecord::Migration
  def up
    add_column :members, :member_since_date, :datetime
  end

  def downs
    remove_column :members, :member_since_date
  end
end
