class CreateTermsOfMemberships < ActiveRecord::Migration
  def up
    create_table :terms_of_memberships, {:id => false} do |t|
      t.string :name
      t.text :description
      t.integer :club_id, :limit => 8
      t.integer :trial_days, :default => 30
      t.string :mode, :default => 'development'
      t.boolean :needs_enrollment_approval, :default => false
      t.integer :grace_period, :default => 0
      t.decimal :installment_amount, :default => 0.0
      t.string :installment_type, :default => '30.days'
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE terms_of_memberships ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :terms_of_memberships
  end  
end
