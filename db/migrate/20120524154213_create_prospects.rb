class CreateProspects < ActiveRecord::Migration
  def up
  	create_table :prospects do |t|
	  t.string :first_name
	  t.string :last_name
	  t.string :address
	  t.string :city
	  t.string :state
	  t.string :zip
	  t.string :email
      t.string :phone
	  t.string :url_landing
	  t.datetime :birth_date
	  t.string :user_id
	  t.string :preferences
	  t.integer :product_id
	  t.string :mega_channel
	  t.string :reporting_code
	  t.string :ip_address
	  t.integer :user_agent
	  t.string :referral_host
	  t.string :referral_parameters
	  t.string :cookie_value
    end
  end

  def down
  	drop_table :prospects
  end
end
