class DropProspectTable < ActiveRecord::Migration
  def up
  	drop_table :prospects
  end

  def down
  	create_table :prospects do |t|
  	  t.uuid :string, :limit => 36
	  t.string :first_name
	  t.string :last_name
	  t.string :address
	  t.string :city
	  t.string :state
	  t.string :zip
	  t.string :email
      t.string :phone_number
	  t.string :url_landing
	  t.integer :club_id, :limit => 8
	  t.integer :terms_of_membership_id, :limit => 8
	  t.datetime :birth_date
	  t.date :created_at
	  t.date :updated_at
	  t.string :user_id
	  t.text :preferences                 
	  t.integer :product_sku
	  t.string :mega_channel
	  t.string :marketing_code
	  t.string :ip_address
	  t.string :country 
	  t.string :user_agent
	  t.string :referral_host
	  t.text :referral_parameters		  
	  t.text :cookie_value				  
	  t.boolean :joint, :default => false
    end
  end
end
