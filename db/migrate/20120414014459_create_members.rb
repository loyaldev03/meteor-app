class CreateMembers < ActiveRecord::Migration
  def up
    execute "CREATE TABLE members (id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, " +
      "prefix VARCHAR(255) NOT NULL, PRIMARY KEY (prefix, id));" 
    change_table :members do |t|
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
      t.integer :terms_of_membership_id, :limit => 8
      t.integer :partner_id, :limit => 8
      t.integer :club_id, :limit => 8
      t.string :status
      t.integer :bill_date
      t.integer :enroll_attempts, :default => 0
      t.string :external_id
      t.datetime :join_date
      t.integer :created_by_id
      t.datetime :next_bill_date
      t.integer :quota, :default => 0
      t.timestamps
    end
  end
  def down
    drop_table :members
  end
end
