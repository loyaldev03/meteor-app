class ChangeWrongAddressOnMember < ActiveRecord::Migration
  def up
    remove_column :members, :wrong_address
    add_column :members, :wrong_address, :string
  end

  def down
  	remove_column :members, :wrong_address
  end
end
