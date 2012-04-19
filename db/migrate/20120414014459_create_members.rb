class CreateMembers < ActiveRecord::Migration
  def up
    execute "CREATE TABLE members (visible_id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, club_id BIGINT(20) NOT NULL, PRIMARY KEY (club_id, visible_id));" 
    change_table :members do |t|
      t.string :uuid, :limit => 36
      t.string :external_id
      t.text :description
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :home_phone
      t.string :work_phone
      t.string :country
      t.string :status
      t.integer :terms_of_membership_id, :limit => 8
      t.integer :partner_id, :limit => 8
      t.integer :enroll_attempts, :default => 0
      t.datetime :join_date
      t.date :cancel_date
      t.date :bill_date
      t.date :next_retry_bill_date
      t.integer :created_by_id
      t.integer :quota, :default => 0
      t.boolean :recyle, :default => false
      t.timestamps
    end
  end
  def down
    drop_table :members
  end
end
