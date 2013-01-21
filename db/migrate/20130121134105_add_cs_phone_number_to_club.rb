class AddCsPhoneNumberToClub < ActiveRecord::Migration
  def up
  	add_column :clubs, :cs_phone_number, :string
  end

  def down
  	remove_column :clubs, :cs_phone_number
  end
end
