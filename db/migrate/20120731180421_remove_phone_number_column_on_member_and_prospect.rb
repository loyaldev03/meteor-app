class RemovePhoneNumberColumnOnMemberAndProspect < ActiveRecord::Migration
  def up
  	remove_column :members, :phone_number
  	remove_column :prospects, :phone_number

  	# Run this script when migration on your console.
	# Member.all.each do |m|
	#   m.update_attributes(:phone_country_code => 123, :phone_area_code => 123, :phone_local_number => 1234)
	#   m.save
	# end

  end

  def down
  	add_column :members, :phone_number, :string
  	add_column :prospects, :phone_number, :string
  end
end
