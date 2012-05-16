class AddUnsubscribedOnMembers < ActiveRecord::Migration
  def up
    add_column :members, :email_unsubscribed_at, :date
  end

  def down
    remove_column :members, :email_unsubscribed_at
  end
end
