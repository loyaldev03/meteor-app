class AddPardotInformation < ActiveRecord::Migration
  def up
    add_column :clubs, :pardot_email, :string
    add_column :clubs, :pardot_password, :string
    add_column :clubs, :pardot_user_key, :string
    drop_table :email_templates
    drop_table :communications
  end

  def down
    remove_column :clubs, :pardot_email, :string
    remove_column :clubs, :pardot_password, :string
    remove_column :clubs, :pardot_user_key, :string

    create_table "communications", :force => true do |t|
      t.string   "member_id",           :limit => 36
      t.string   "template_name"
      t.string   "email"
      t.datetime "scheduled_at"
      t.datetime "processed_at"
      t.string   "client"
      t.string   "external_attributes"
      t.string   "template_type"
      t.boolean  "sent_success"
      t.text     "request"
      t.text     "response"
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end
    add_index "communications", ["member_id"], :name => "index_communications_on_member_id"

    create_table "email_templates", :force => true do |t|
      t.string   "name"
      t.string   "client"
      t.text     "external_attributes"
      t.string   "template_type"
      t.integer  "terms_of_membership_id", :limit => 8
      t.datetime "created_at",                                         :null => false
      t.datetime "updated_at",                                         :null => false
      t.integer  "days_after_join_date",                :default => 0
    end

  end
end
