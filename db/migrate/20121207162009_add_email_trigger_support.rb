class AddEmailTriggerSupport < ActiveRecord::Migration
  def up
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
      t.integer  "days_after_join_date",                :default => 0
      t.datetime "created_at",                                         :null => false
      t.datetime "updated_at",                                         :null => false
    end
  end

  def down
  	drop_table :email_templates
  	drop_table :communications
  end
end
