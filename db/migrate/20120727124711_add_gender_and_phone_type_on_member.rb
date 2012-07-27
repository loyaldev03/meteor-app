class AddGenderAndPhoneTypeOnMember < ActiveRecord::Migration
  def up
  	add_column :members, :gender, :string, :limit => 1
  	add_column :members, :type_of_phone_number, :string, :limit => 36
  end

  def down
  	remove_column :members, :gender
  	remove_column :members, :type_of_phone_number
  end
end
