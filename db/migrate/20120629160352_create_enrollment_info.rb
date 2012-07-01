class CreateEnrollmentInfo < ActiveRecord::Migration
  def up
  	create_table :enrollment_infos do |t|
      t.string :member_id
      t.decimal :enrollment_amount
      t.string :product_sku               #(ex :product_id)
      t.text :product_description
      t.string :mega_channel
      t.string :marketing_code            #(ex: reporting_code)
      t.string :fulfillment_code
      t.string :ip_address
      t.string :user_agent
      t.string :referral_host
      t.text :referral_parameters
      t.string :referral_path
      t.string :user_id
      t.string :landing_url
      t.integer :terms_of_membership_id
      t.text :preferences
      t.text :cookie_value
      t.boolean :cookie_set
      t.text :campaign_medium
      t.text :campaign_description
      t.integer :campaign_medium_version
      t.boolean :is_joint
    end
    remove_column :members, :enrollment_info 
  end

  def down
  	add_column :members, :enrollment_info, :string
  	drop_table :enrollment_infos
  end
end


