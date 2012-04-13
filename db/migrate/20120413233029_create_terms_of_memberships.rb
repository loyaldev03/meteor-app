class CreateTermsOfMemberships < ActiveRecord::Migration
  def up
    create_table :terms_of_memberships, {:id => false} do |t|
      t.integer :club_id, :limit => 8
      t.decimal :year_price, :default => 0.0
      t.integer :trial_days, :default => 30
      t.string :mode, :default => 'development'
      t.boolean :needs_enrollment_approval, :default => false
      t.decimal :enrollment_price, :default => 0.0
      t.integer :max_reactivations, :default => 3
      t.integer :grace_period, :default => 0
      t.string :bill_type, :default => 'monthly'
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE terms_of_memberships ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :terms_of_memberships
  end  
end
