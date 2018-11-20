class AddVipMemberFlagOnUsers < ActiveRecord::Migration
  def change
    add_column :users, :vip_member, :boolean,       default: false
  end
end
