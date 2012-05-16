class AddUnsubscribedOnMembers < ActiveRecord::Migration
  def up
    add_column :members, :email_unsubscribed, :boolean, :default => false
  end

  def down
    remove_column :members, :email_unsubscribed
  end
end
