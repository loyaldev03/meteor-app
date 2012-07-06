class DatabaseStrucutureNormalizationAfterMigrationMerge < ActiveRecord::Migration
  def change
    add_column :club_cash_transactions, :created_at, :datetime, :null => false
    add_column :club_cash_transactions, :updated_at, :datetime, :null => false
    change_column :club_cash_transactions, :member_id, :string, :limit => 36
    execute "ALTER TABLE club_cash_transactions CHANGE COLUMN id id BIGINT(20) NOT NULL AUTO_INCREMENT;"

    change_column :clubs, :drupal_domain_id, :integer, :limit => 8

    execute "ALTER TABLE communications CHANGE COLUMN id id BIGINT(20) NOT NULL AUTO_INCREMENT;"
    add_index "communications", ["member_id"], :name => "index_communications_on_member_id"    

    change_column :email_templates, :external_attributes, :text

    execute "ALTER TABLE enrollment_infos CHANGE COLUMN id id BIGINT(20) NOT NULL AUTO_INCREMENT;"
    change_column :enrollment_infos, :member_id, :string, :limit => 36
    change_column :enrollment_infos, :enrollment_amount, :float
    change_column :enrollment_infos, :terms_of_membership_id, :integer, :limit => 8

    execute "ALTER TABLE fulfillments CHANGE COLUMN id id BIGINT(20) NOT NULL AUTO_INCREMENT;"

    change_column :members, :api_id, :string
    add_column :members, :birth_date, :date
    remove_index "members", ["uuid"]
    add_index "members", ["uuid"], :unique => true

    add_index "prospects", ["uuid"], :unique => true

    add_index "transactions", ["uuid"], :unique => true
  end
end
