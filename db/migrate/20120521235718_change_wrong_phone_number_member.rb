class ChangeWrongPhoneNumberMember < ActiveRecord::Migration
  def up
  	remove_column :members, :wrong_phone_number
  	add_column :members, :wrong_phone_number, :string
  end

  def down
  	remove_column :members, :wrong_phone_number
  end
end
