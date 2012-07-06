class FirstDatabaseVersionMergedMigrations < ActiveRecord::Migration
  def change
    create_table "agents", :force => true do |t|
      t.string   "email",                  :default => "",       :null => false
      t.string   "encrypted_password",     :default => "",       :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",          :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.string   "password_salt"
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string   "unconfirmed_email"
      t.integer  "failed_attempts",        :default => 0
      t.string   "unlock_token"
      t.datetime "locked_at"
      t.string   "authentication_token"
      t.string   "username"
      t.string   "first_name"
      t.string   "last_name"
      t.text     "description"
      t.datetime "deleted_at"
      t.datetime "created_at",                                   :null => false
      t.datetime "updated_at",                                   :null => false
      t.string   "roles",                  :default => "--- []"
    end

    add_index "agents", ["authentication_token"], :name => "index_agents_on_authentication_token", :unique => true
    add_index "agents", ["confirmation_token"], :name => "index_agents_on_confirmation_token", :unique => true
    add_index "agents", ["email"], :name => "index_agents_on_email", :unique => true
    add_index "agents", ["reset_password_token"], :name => "index_agents_on_reset_password_token", :unique => true
    add_index "agents", ["unlock_token"], :name => "index_agents_on_unlock_token", :unique => true

    create_table "club_cash_transactions", :force => true do |t|
      t.string "member_id"
      t.float  "amount",      :default => 0.0
      t.text   "description"
    end

    create_table "clubs", {:id => false} do |t|
      t.text     "description"
      t.string   "name"
      t.integer  "partner_id",        :limit => 8
      t.string   "logo_file_name"
      t.string   "logo_content_type"
      t.integer  "logo_file_size"
      t.datetime "logo_updated_at"
      t.datetime "deleted_at"
      t.datetime "created_at",                     :null => false
      t.datetime "updated_at",                     :null => false
      t.integer  "drupal_domain_id"
      t.string   "api_username"
      t.string   "api_password"
      t.string   "api_type"
    end
    execute "ALTER TABLE clubs ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

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

    create_table "credit_cards", {:id => false} do |t|
      t.string   "member_id",                 :limit => 36
      t.boolean  "active",                                  :default => true
      t.boolean  "blacklisted",                             :default => false
      t.string   "encrypted_number"
      t.integer  "expire_month"
      t.integer  "expire_year"
      t.datetime "created_at",                                                 :null => false
      t.datetime "updated_at",                                                 :null => false
      t.datetime "last_successful_bill_date"
      t.string   "last_digits",               :limit => 4
    end
    execute "ALTER TABLE credit_cards ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    add_index "credit_cards", ["member_id"], :name => "index_credit_cards_on_member_id"

    create_table "decline_strategies", {:id => false} do |t|
      t.string   "gateway"
      t.string   "installment_type", :default => "monthly"
      t.string   "credit_card_type", :default => "all"
      t.string   "response_code"
      t.integer  "limit",            :default => 0
      t.integer  "days",             :default => 0
      t.string   "decline_type",     :default => "soft"
      t.text     "notes"
      t.datetime "deleted_at"
      t.datetime "created_at",                              :null => false
      t.datetime "updated_at",                              :null => false
    end
    execute "ALTER TABLE decline_strategies ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    create_table "delayed_jobs", :force => true do |t|
      t.integer  "priority",   :default => 0
      t.integer  "attempts",   :default => 0
      t.text     "handler"
      t.text     "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.string   "queue"
      t.datetime "created_at",                :null => false
      t.datetime "updated_at",                :null => false
    end

    add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

    create_table "domains", {:id => false} do |t|
      t.string   "url"
      t.text     "description"
      t.text     "data_rights"
      t.integer  "partner_id",  :limit => 8
      t.boolean  "hosted",                   :default => false
      t.datetime "deleted_at"
      t.datetime "created_at",                                  :null => false
      t.datetime "updated_at",                                  :null => false
      t.integer  "club_id",     :limit => 8
    end
    execute "ALTER TABLE domains ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    create_table "email_templates", :force => true do |t|
      t.string   "name"
      t.string   "client"
      t.string   "external_attributes"
      t.string   "template_type"
      t.integer  "terms_of_membership_id", :limit => 8
      t.datetime "created_at",                                         :null => false
      t.datetime "updated_at",                                         :null => false
      t.integer  "days_after_join_date",                :default => 0
    end

    create_table "enrollment_infos", :force => true do |t|
      t.string  "member_id"
      t.decimal "enrollment_amount",                     :precision => 10, :scale => 0
      t.string  "product_sku"
      t.text    "product_description"
      t.string  "mega_channel"
      t.string  "marketing_code"
      t.string  "fulfillment_code"
      t.string  "ip_address"
      t.string  "user_agent"
      t.string  "referral_host"
      t.text    "referral_parameters"
      t.string  "referral_path"
      t.string  "user_id"
      t.string  "landing_url"
      t.integer "terms_of_membership_id"
      t.text    "preferences"
      t.text    "cookie_value"
      t.boolean "cookie_set"
      t.text    "campaign_medium"
      t.text    "campaign_description"
      t.integer "campaign_medium_version"
      t.boolean "is_joint"
      t.string  "prospect_id",             :limit => 36
    end

    create_table "enumerations", :force => true do |t|
      t.string   "type"
      t.string   "name"
      t.integer  "position"
      t.integer  "club_id",    :limit => 8
      t.boolean  "visible",                 :default => true
      t.datetime "deleted_at"
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
    end

    create_table "fulfillments", :force => true do |t|
      t.string   "member_id",    :limit => 36
      t.string   "product"
      t.datetime "assigned_at"
      t.datetime "delivered_at"
      t.datetime "renewable_at"
      t.string   "status"
      t.datetime "created_at",                 :null => false
      t.datetime "updated_at",                 :null => false
    end

    create_table "member_notes", {:id => false} do |t|
      t.string   "member_id",             :limit => 36
      t.integer  "created_by_id",         :limit => 8
      t.text     "description"
      t.integer  "disposition_type_id"
      t.integer  "communication_type_id"
      t.datetime "created_at",                          :null => false
      t.datetime "updated_at",                          :null => false
    end

    execute "ALTER TABLE member_notes ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"
    add_index "member_notes", ["member_id"], :name => "index_member_notes_on_member_id"

    execute "CREATE TABLE members (club_id BIGINT(20) NOT NULL, visible_id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT, PRIMARY KEY (club_id, visible_id)) ENGINE=MyISAM;" 
    change_table :members do |t|
      t.string   "uuid",                   :limit => 36
      t.string   "external_id"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "country"
      t.string   "status"
      t.integer  "terms_of_membership_id", :limit => 8
      t.datetime "join_date"
      t.date     "cancel_date"
      t.date     "bill_date"
      t.date     "next_retry_bill_date"
      t.integer  "created_by_id"
      t.integer  "quota",                                :default => 0
      t.integer  "recycled_times",                       :default => 0
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "phone_number"
      t.boolean  "blacklisted",                          :default => false
      t.integer  "member_group_type_id"
      t.integer  "reactivation_times",                   :default => 0
      t.datetime "member_since_date"
      t.string   "wrong_address"
      t.string   "wrong_phone_number"
      t.integer  "api_id"
      t.datetime "last_synced_at"
      t.text     "last_sync_error"
      t.float    "club_cash_amount",                     :default => 0.0
      t.boolean  "joint",                                :default => false
      t.date     "club_cash_expire_date"
    end

    add_index "members", ["club_id"], :name => "index_members_on_club_id"
    add_index "members", ["email"], :name => "index_members_on_email"
    add_index "members", ["uuid"], :name => "index_members_on_uuid"

    create_table "operations", {:id => false} do |t|
      t.string   "member_id",      :limit => 36
      t.text     "description"
      t.datetime "operation_date"
      t.integer  "created_by_id"
      t.string   "resource_type"
      t.string   "resource_id"
      t.datetime "created_at",                   :null => false
      t.datetime "updated_at",                   :null => false
      t.text     "notes"
      t.integer  "operation_type"
    end

    execute "ALTER TABLE operations ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"
    add_index "operations", ["member_id"], :name => "index_operations_on_member_id"

    create_table "partners", {:id => false} do |t|
      t.string   "prefix"
      t.string   "name"
      t.string   "contract_uri"
      t.string   "website_url"
      t.text     "description"
      t.datetime "deleted_at"
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
    end
    execute "ALTER TABLE partners ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    create_table "payment_gateway_configurations", {:id => false} do |t|
      t.string   "report_group"
      t.string   "merchant_key"
      t.string   "login"
      t.string   "password"
      t.string   "mode",                          :default => "development"
      t.string   "descriptor_name"
      t.string   "descriptor_phone"
      t.string   "order_mark"
      t.string   "gateway"
      t.integer  "club_id",          :limit => 8
      t.datetime "deleted_at"
      t.datetime "created_at",                                               :null => false
      t.datetime "updated_at",                                               :null => false
    end
    execute "ALTER TABLE payment_gateway_configurations ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    create_table "prospects", :id => false, :force => true do |t|
      t.string   "uuid",                   :limit => 36
      t.string   "first_name"
      t.string   "last_name"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "email"
      t.string   "phone_number"
      t.string   "url_landing"
      t.integer  "club_id",                :limit => 8
      t.integer  "terms_of_membership_id", :limit => 8
      t.date     "birth_date"
      t.datetime "created_at",                                              :null => false
      t.datetime "updated_at",                                              :null => false
      t.string   "user_id"
      t.text     "preferences"
      t.string   "product_sku"
      t.string   "mega_channel"
      t.string   "marketing_code"
      t.string   "ip_address"
      t.string   "country"
      t.string   "user_agent"
      t.string   "referral_host"
      t.text     "referral_parameters"
      t.text     "cookie_value"
      t.boolean  "joint",                                :default => false
    end

    create_table "terms_of_memberships", {:id => false} do |t|
      t.string   "name"
      t.text     "description"
      t.integer  "club_id",                   :limit => 8
      t.integer  "trial_days",                             :default => 30
      t.string   "mode",                                   :default => "development"
      t.boolean  "needs_enrollment_approval",              :default => false
      t.integer  "grace_period",                           :default => 0
      t.float    "installment_amount",                     :default => 0.0
      t.string   "installment_type",                       :default => "30.days"
      t.datetime "deleted_at"
      t.datetime "created_at",                                                        :null => false
      t.datetime "updated_at",                                                        :null => false
      t.integer  "club_cash_amount",                       :default => 0
    end
    execute "ALTER TABLE terms_of_memberships ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;"

    create_table "transactions", :id => false, :force => true do |t|
      t.string   "uuid",                             :limit => 36
      t.string   "member_id",                        :limit => 36
      t.integer  "terms_of_membership_id",           :limit => 8
      t.integer  "payment_gateway_configuration_id", :limit => 8
      t.string   "report_group"
      t.string   "merchant_key"
      t.string   "login"
      t.string   "password"
      t.string   "mode"
      t.string   "descriptor_name"
      t.string   "descriptor_phone"
      t.string   "order_mark"
      t.string   "gateway"
      t.string   "encrypted_number"
      t.integer  "expire_month"
      t.integer  "expire_year"
      t.boolean  "recurrent",                                      :default => false
      t.string   "transaction_type"
      t.string   "invoice_number"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "phone_number"
      t.string   "email"
      t.string   "address"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.float    "amount"
      t.integer  "decline_strategy_id",              :limit => 8
      t.text     "response"
      t.string   "response_code"
      t.string   "response_result"
      t.string   "response_transaction_id"
      t.string   "response_auth_code"
      t.datetime "created_at",                                                        :null => false
      t.datetime "updated_at",                                                        :null => false
      t.integer  "credit_card_id",                   :limit => 8
      t.float    "refunded_amount",                                :default => 0.0
    end
  end
end
