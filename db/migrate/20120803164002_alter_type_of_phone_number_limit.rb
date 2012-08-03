class AlterTypeOfPhoneNumberLimit < ActiveRecord::Migration
  def up
  	change_column :members, :type_of_phone_number, :string, :limit => 255
  end

  def down
  	change_column :members, :type_of_phone_number, :string, :limit => 36
  end
end
