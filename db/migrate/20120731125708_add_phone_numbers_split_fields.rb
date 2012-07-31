class AddPhoneNumbersSplitFields < ActiveRecord::Migration
  def up
  	add_column :members, :phone_country_code, :integer
  	add_column :members, :phone_area_code, :integer
  	add_column :members, :phone_local_number, :integer
  	add_column :prospects, :phone_country_code, :integer
  	add_column :prospects, :phone_area_code, :integer
  	add_column :prospects, :phone_local_number, :integer
  end

  def down
  	remove_column :members, :phone_country_code
  	remove_column :members, :phone_area_code
  	remove_column :members, :phone_local_number
   	remove_column :prospects, :phone_country_code
  	remove_column :prospects, :phone_area_code
  	remove_column :prospects, :phone_local_number
  end
end
