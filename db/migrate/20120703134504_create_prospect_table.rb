class CreateProspectTable < ActiveRecord::Migration
  def up
  	create_table :prospects, :id => false do |t|
  	  t.string :uuid, :limit => 36
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
	  t.date :birth_date
	  t.timestamps :created_at
	  t.timestamps :updated_at
	  t.string :user_id
	  t.text :preferences                  #Should it be 'text' or 'string'?
	  t.string :product_sku
	  t.string :mega_channel
	  t.string :marketing_code
	  t.string :ip_address
	  t.string :country 
	  t.string :user_agent
	  t.string :referral_host
	  t.text :referral_parameters		   #Should it be 'text' or 'string'?
	  t.text :cookie_value				   #Should it be 'text' or 'string'?
	  t.boolean :joint, :default => false
    end

  end

  def down
  	drop_table :prospects
  end

end
