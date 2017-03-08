# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170303185717) do

  create_table "agents", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "password_salt",          limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",        limit: 4,   default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",   limit: 255
    t.string   "username",               limit: 255
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "roles",                  limit: 255, default: ""
  end

  add_index "agents", ["authentication_token"], name: "index_agents_on_authentication_token", unique: true, using: :btree
  add_index "agents", ["confirmation_token"], name: "index_agents_on_confirmation_token", unique: true, using: :btree
  add_index "agents", ["email"], name: "index_agents_on_email", unique: true, using: :btree
  add_index "agents", ["reset_password_token"], name: "index_agents_on_reset_password_token", unique: true, using: :btree
  add_index "agents", ["unlock_token"], name: "index_agents_on_unlock_token", unique: true, using: :btree

  create_table "campaign_days", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4
    t.date     "date"
    t.decimal  "spent",                 precision: 10
    t.integer  "reached",     limit: 4
    t.integer  "converted",   limit: 4
    t.integer  "meta",        limit: 4,                default: 0
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  add_index "campaign_days", ["campaign_id", "date"], name: "index_campaign_days_on_campaign_id_and_date", unique: true, using: :btree

  create_table "campaign_products", force: :cascade do |t|
    t.integer "campaign_id", limit: 4
    t.integer "product_id",  limit: 4
    t.string  "label",       limit: 255, null: false
    t.integer "position",    limit: 4
  end

  add_index "campaign_products", ["campaign_id"], name: "index_campaign_products_on_campaign_id", using: :btree
  add_index "campaign_products", ["product_id"], name: "index_campaign_products_on_product_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.decimal  "enrollment_price",                     precision: 11, scale: 2, default: 0.0
    t.date     "initial_date"
    t.date     "finish_date"
    t.integer  "campaign_type",          limit: 4
    t.integer  "transport",              limit: 4
    t.string   "transport_campaign_id",  limit: 255
    t.string   "utm_medium",             limit: 255
    t.string   "utm_content",            limit: 255
    t.string   "audience",               limit: 255
    t.string   "campaign_code",          limit: 255
    t.integer  "club_id",                limit: 4
    t.integer  "terms_of_membership_id", limit: 4
    t.datetime "created_at",                                                                                              null: false
    t.datetime "updated_at",                                                                                              null: false
    t.string   "landing_name",           limit: 255
    t.text     "landing_url",            limit: 65535
    t.integer  "products_count",         limit: 4,                              default: 0
    t.string   "delivery_date",          limit: 255,                            default: "3 - 5 weeks from date ordered"
    t.string   "slug",                   limit: 100
  end

  add_index "campaigns", ["club_id"], name: "index_campaigns_on_club_id", using: :btree
  add_index "campaigns", ["finish_date"], name: "index_campaigns_on_finish_date", using: :btree
  add_index "campaigns", ["initial_date"], name: "index_campaigns_on_initial_date", using: :btree
  add_index "campaigns", ["slug"], name: "index_campaigns_on_slug", using: :btree
  add_index "campaigns", ["terms_of_membership_id"], name: "index_campaigns_on_terms_of_membership_id", using: :btree

  create_table "campaigns_preference_groups", id: false, force: :cascade do |t|
    t.integer "preference_group_id", limit: 4
    t.integer "campaign_id",         limit: 4
  end

  add_index "campaigns_preference_groups", ["campaign_id"], name: "index_campaigns_preference_groups_on_campaign_id", using: :btree
  add_index "campaigns_preference_groups", ["preference_group_id"], name: "index_campaigns_preference_groups_on_preference_group_id", using: :btree

  create_table "club_cash_transactions", force: :cascade do |t|
    t.decimal  "amount",                    precision: 11, scale: 2, default: 0.0
    t.text     "description", limit: 65535
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "user_id",     limit: 8
  end

  add_index "club_cash_transactions", ["user_id"], name: "index_member_id", using: :btree

  create_table "club_roles", force: :cascade do |t|
    t.integer  "agent_id",   limit: 4
    t.integer  "club_id",    limit: 8
    t.string   "role",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "club_roles", ["agent_id"], name: "index_club_roles_on_agent_id", using: :btree
  add_index "club_roles", ["club_id"], name: "index_club_roles_on_club_id", using: :btree

  create_table "clubs", force: :cascade do |t|
    t.text     "description",                          limit: 65535
    t.string   "name",                                 limit: 255
    t.integer  "partner_id",                           limit: 8
    t.string   "logo_file_name",                       limit: 255
    t.string   "logo_content_type",                    limit: 255
    t.integer  "logo_file_size",                       limit: 4
    t.datetime "logo_updated_at"
    t.datetime "deleted_at"
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.integer  "drupal_domain_id",                     limit: 8
    t.string   "api_username",                         limit: 255
    t.string   "api_password",                         limit: 255
    t.string   "api_type",                             limit: 255
    t.string   "theme",                                limit: 255,   default: "application"
    t.boolean  "requires_external_id",                               default: false
    t.string   "time_zone",                            limit: 255,   default: "UTC"
    t.boolean  "billing_enable",                                     default: true
    t.string   "cs_phone_number",                      limit: 255
    t.boolean  "family_memberships_allowed",                         default: false
    t.boolean  "club_cash_enable",                                   default: true
    t.text     "marketing_tool_attributes",            limit: 65535
    t.integer  "members_count",                        limit: 4
    t.string   "member_banner_url",                    limit: 255
    t.string   "member_landing_url",                   limit: 255
    t.string   "non_member_banner_url",                limit: 255
    t.string   "non_member_landing_url",               limit: 255
    t.string   "marketing_tool_client",                limit: 255
    t.string   "payment_gateway_errors_email",         limit: 255
    t.string   "twitter_url",                          limit: 255
    t.string   "facebook_url",                         limit: 255
    t.string   "store_url",                            limit: 255
    t.string   "checkout_url",                         limit: 255
    t.string   "cs_email",                             limit: 255
    t.text     "privacy_policy_url",                   limit: 65535
    t.string   "favicon_url_file_name",                limit: 255
    t.string   "favicon_url_content_type",             limit: 255
    t.integer  "favicon_url_file_size",                limit: 4
    t.datetime "favicon_url_updated_at"
    t.string   "header_image_url_file_name",           limit: 255
    t.string   "header_image_url_content_type",        limit: 255
    t.integer  "header_image_url_file_size",           limit: 4
    t.datetime "header_image_url_updated_at"
    t.string   "result_pages_image_url_file_name",     limit: 255
    t.string   "result_pages_image_url_content_type",  limit: 255
    t.integer  "result_pages_image_url_file_size",     limit: 4
    t.datetime "result_pages_image_url_updated_at"
    t.text     "checkout_page_bonus_gift_box_content", limit: 65535
    t.text     "thank_you_page_content",               limit: 65535
    t.text     "duplicated_page_content",              limit: 65535
    t.text     "error_page_content",                   limit: 65535
    t.text     "checkout_page_footer",                 limit: 65535
    t.text     "result_page_footer",                   limit: 65535
    t.text     "css_style",                            limit: 65535
    t.text     "unavailable_campaign_url",             limit: 65535
  end

  add_index "clubs", ["drupal_domain_id"], name: "index_drupal_domain_id", using: :btree
  add_index "clubs", ["partner_id"], name: "index_partner_id", using: :btree

  create_table "communications", force: :cascade do |t|
    t.string   "template_name",       limit: 255
    t.string   "email",               limit: 255
    t.datetime "scheduled_at"
    t.datetime "processed_at"
    t.string   "client",              limit: 255
    t.string   "external_attributes", limit: 255
    t.string   "template_type",       limit: 255
    t.boolean  "sent_success"
    t.text     "response",            limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "user_id",             limit: 8
  end

  add_index "communications", ["user_id"], name: "index_communications_on_user_id", using: :btree

  create_table "credit_cards", force: :cascade do |t|
    t.boolean  "active",                                default: true
    t.boolean  "blacklisted",                           default: false
    t.integer  "expire_month",              limit: 4
    t.integer  "expire_year",               limit: 4
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.datetime "last_successful_bill_date"
    t.string   "last_digits",               limit: 4
    t.string   "cc_type",                   limit: 255
    t.datetime "aus_sent_at"
    t.datetime "aus_answered_at"
    t.string   "aus_status",                limit: 255
    t.string   "token",                     limit: 255
    t.integer  "user_id",                   limit: 8
    t.string   "gateway",                   limit: 255
  end

  add_index "credit_cards", ["token"], name: "index_credit_card_on_token", using: :btree
  add_index "credit_cards", ["user_id"], name: "index2", using: :btree

  create_table "decline_strategies", force: :cascade do |t|
    t.string   "gateway",          limit: 255
    t.string   "installment_type", limit: 255,   default: "monthly"
    t.string   "credit_card_type", limit: 255,   default: "all"
    t.string   "response_code",    limit: 255
    t.integer  "max_retries",      limit: 4,     default: 0
    t.integer  "days",             limit: 4,     default: 0
    t.string   "decline_type",     limit: 255,   default: "soft"
    t.text     "notes",            limit: 65535
    t.datetime "deleted_at"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0
    t.integer  "attempts",   limit: 4,     default: 0
    t.text     "handler",    limit: 65535
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "domains", force: :cascade do |t|
    t.string   "url",         limit: 255
    t.text     "description", limit: 65535
    t.text     "data_rights", limit: 65535
    t.integer  "partner_id",  limit: 8
    t.boolean  "hosted",                    default: false
    t.datetime "deleted_at"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "club_id",     limit: 8
  end

  add_index "domains", ["club_id"], name: "index_club_id", using: :btree
  add_index "domains", ["partner_id"], name: "index_domains_on_partner_id", using: :btree

  create_table "email_templates", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "client",                 limit: 255
    t.text     "external_attributes",    limit: 65535
    t.string   "template_type",          limit: 255
    t.integer  "terms_of_membership_id", limit: 8
    t.integer  "days",                   limit: 4,     default: 0
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  add_index "email_templates", ["terms_of_membership_id"], name: "index_terms_of_membership_id", using: :btree

  create_table "enrollment_infos", force: :cascade do |t|
    t.decimal  "enrollment_amount",                     precision: 11, scale: 2, default: 0.0
    t.text     "product_sku",             limit: 65535
    t.text     "product_description",     limit: 65535
    t.string   "mega_channel",            limit: 255
    t.string   "marketing_code",          limit: 255
    t.string   "fulfillment_code",        limit: 255
    t.string   "ip_address",              limit: 255
    t.string   "user_agent",              limit: 255
    t.string   "referral_host",           limit: 255
    t.text     "referral_parameters",     limit: 65535
    t.string   "referral_path",           limit: 255
    t.string   "visitor_id",              limit: 255
    t.string   "landing_url",             limit: 255
    t.integer  "terms_of_membership_id",  limit: 8
    t.text     "preferences",             limit: 65535
    t.text     "cookie_value",            limit: 65535
    t.boolean  "cookie_set"
    t.text     "campaign_medium",         limit: 65535
    t.text     "campaign_description",    limit: 65535
    t.text     "campaign_medium_version", limit: 65535
    t.boolean  "joint"
    t.string   "prospect_id",             limit: 36
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.integer  "membership_id",           limit: 8
    t.integer  "user_id",                 limit: 8
    t.string   "source",                  limit: 255
    t.integer  "product_id",              limit: 4
  end

  add_index "enrollment_infos", ["created_at"], name: "index_created_at", using: :btree
  add_index "enrollment_infos", ["membership_id"], name: "index_membership_id", using: :btree
  add_index "enrollment_infos", ["product_id"], name: "index_enrollment_infos_on_product_id", using: :btree
  add_index "enrollment_infos", ["terms_of_membership_id"], name: "index_terms_of_membership_id", using: :btree
  add_index "enrollment_infos", ["user_id"], name: "index_enrollment_info_on_member_id", using: :btree

  create_table "enumerations", force: :cascade do |t|
    t.string   "type",       limit: 40
    t.string   "name",       limit: 255
    t.integer  "position",   limit: 4
    t.integer  "club_id",    limit: 8
    t.boolean  "visible",                default: true
    t.datetime "deleted_at"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  add_index "enumerations", ["club_id"], name: "index_enumerations_on_club_id", using: :btree
  add_index "enumerations", ["visible", "type"], name: "index_enumerations_on_visible_and_type", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "fulfillment_files", force: :cascade do |t|
    t.integer  "agent_id",          limit: 4
    t.integer  "club_id",           limit: 8
    t.date     "initial_date"
    t.date     "end_date"
    t.boolean  "all_times",                     default: false
    t.string   "product",           limit: 255
    t.string   "status",            limit: 255, default: "in_process"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.integer  "fulfillment_count", limit: 4,   default: 0
  end

  add_index "fulfillment_files", ["agent_id"], name: "index_fulfillment_files_on_agent_id", using: :btree
  add_index "fulfillment_files", ["club_id"], name: "index_fulfillment_files_on_club_id", using: :btree

  create_table "fulfillment_files_fulfillments", id: false, force: :cascade do |t|
    t.integer "fulfillment_id",      limit: 8
    t.integer "fulfillment_file_id", limit: 4
  end

  add_index "fulfillment_files_fulfillments", ["fulfillment_file_id"], name: "index_fulfillment_file_id", using: :btree
  add_index "fulfillment_files_fulfillments", ["fulfillment_id"], name: "index_fulfillment_files_fulfillments_on_fulfillment_id", using: :btree

  create_table "fulfillments", force: :cascade do |t|
    t.string   "product_sku",                     limit: 255
    t.datetime "assigned_at"
    t.datetime "renewable_at"
    t.string   "status",                          limit: 255,                         default: "not_processed"
    t.datetime "created_at",                                                                                    null: false
    t.datetime "updated_at",                                                                                    null: false
    t.string   "tracking_code",                   limit: 255
    t.boolean  "recurrent",                                                           default: false
    t.boolean  "renewed",                                                             default: false
    t.string   "product_package",                 limit: 255
    t.integer  "user_id",                         limit: 8
    t.integer  "club_id",                         limit: 8
    t.string   "full_name",                       limit: 255
    t.string   "full_address",                    limit: 255
    t.string   "full_phone_number",               limit: 255
    t.string   "email",                           limit: 255
    t.integer  "email_matches_count",             limit: 4
    t.integer  "full_name_matches_count",         limit: 4
    t.integer  "full_address_matches_count",      limit: 4
    t.integer  "full_phone_number_matches_count", limit: 4
    t.decimal  "average_match_age",                           precision: 6, scale: 2
    t.integer  "matching_fulfillments_count",     limit: 4
    t.integer  "product_id",                      limit: 4
  end

  add_index "fulfillments", ["club_id", "assigned_at", "status"], name: "index_fulfillments_on_club_id_and_assigned_at_and_status", using: :btree
  add_index "fulfillments", ["club_id"], name: "index_fulfillments_on_club_id", using: :btree
  add_index "fulfillments", ["email"], name: "index_fulfillments_on_email", using: :btree
  add_index "fulfillments", ["full_address"], name: "index_fulfillments_on_full_address", using: :btree
  add_index "fulfillments", ["full_name"], name: "index_fulfillments_on_full_name", using: :btree
  add_index "fulfillments", ["full_phone_number"], name: "index_fulfillments_on_full_phone_number", using: :btree
  add_index "fulfillments", ["product_id"], name: "index_fulfillments_on_product_id", using: :btree
  add_index "fulfillments", ["status"], name: "index_fulfillments_on_status", using: :btree
  add_index "fulfillments", ["user_id"], name: "index2", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.string   "status",                 limit: 255
    t.integer  "terms_of_membership_id", limit: 8
    t.datetime "join_date"
    t.datetime "cancel_date"
    t.integer  "created_by_id",          limit: 4
    t.datetime "created_at",                                                                  null: false
    t.datetime "updated_at",                                                                  null: false
    t.integer  "user_id",                limit: 8
    t.integer  "parent_membership_id",   limit: 8
    t.decimal  "enrollment_amount",                    precision: 11, scale: 2, default: 0.0
    t.string   "product_sku",            limit: 255
    t.integer  "product_id",             limit: 4
    t.string   "product_description",    limit: 255
    t.string   "utm_campaign",           limit: 255
    t.string   "audience",               limit: 255
    t.string   "campaign_code",          limit: 255
    t.string   "ip_address",             limit: 255
    t.string   "user_agent",             limit: 255
    t.string   "referral_host",          limit: 255
    t.text     "referral_parameters",    limit: 65535
    t.string   "referral_path",          limit: 255
    t.string   "visitor_id",             limit: 255
    t.string   "landing_url",            limit: 255
    t.text     "preferences",            limit: 65535
    t.string   "cookie_value",           limit: 255
    t.boolean  "cookie_set"
    t.string   "utm_medium",             limit: 255
    t.string   "campaign_description",   limit: 255
    t.string   "utm_content",            limit: 255
    t.boolean  "joint"
    t.integer  "prospect_id",            limit: 4
    t.string   "utm_source",             limit: 255
    t.integer  "campaign_id",            limit: 4
  end

  add_index "memberships", ["campaign_id"], name: "index_memberships_on_campaign_id", using: :btree
  add_index "memberships", ["created_at"], name: "index_created_at", using: :btree
  add_index "memberships", ["created_by_id"], name: "index_memberships_on_created_by_id", using: :btree
  add_index "memberships", ["product_id"], name: "index_memberships_on_product_id", using: :btree
  add_index "memberships", ["prospect_id"], name: "index_memberships_on_prospect_id", using: :btree
  add_index "memberships", ["terms_of_membership_id"], name: "index_terms_of_membership_id", using: :btree
  add_index "memberships", ["user_id"], name: "index2", using: :btree

  create_table "operations", force: :cascade do |t|
    t.text     "description",    limit: 65535
    t.datetime "operation_date"
    t.integer  "created_by_id",  limit: 4
    t.string   "resource_type",  limit: 255
    t.string   "resource_id",    limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.text     "notes",          limit: 65535
    t.integer  "operation_type", limit: 4
    t.integer  "user_id",        limit: 8
    t.integer  "club_id",        limit: 4
  end

  add_index "operations", ["club_id"], name: "index_operations_on_club_id", using: :btree
  add_index "operations", ["created_at"], name: "index_created_at", using: :btree
  add_index "operations", ["created_by_id"], name: "index_operations_on_created_by_id", using: :btree
  add_index "operations", ["resource_type", "resource_id"], name: "index_operations_on_resource_type_and_resource_id", using: :btree
  add_index "operations", ["user_id"], name: "index2", using: :btree

  create_table "partners", force: :cascade do |t|
    t.string   "prefix",       limit: 40
    t.string   "name",         limit: 255
    t.string   "contract_uri", limit: 255
    t.string   "website_url",  limit: 255
    t.text     "description",  limit: 65535
    t.datetime "deleted_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "partners", ["prefix"], name: "index_partners_on_prefix", using: :btree

  create_table "payment_gateway_configurations", force: :cascade do |t|
    t.string   "report_group",     limit: 255
    t.string   "merchant_key",     limit: 255
    t.string   "login",            limit: 255
    t.string   "password",         limit: 255
    t.string   "descriptor_name",  limit: 255
    t.string   "descriptor_phone", limit: 255
    t.string   "gateway",          limit: 255
    t.integer  "club_id",          limit: 8
    t.datetime "deleted_at"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "aus_login",        limit: 255
    t.string   "aus_password",     limit: 255
  end

  add_index "payment_gateway_configurations", ["club_id"], name: "index_club_id", using: :btree

  create_table "preference_groups", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "code",           limit: 255
    t.boolean  "add_by_default"
    t.integer  "club_id",        limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "preference_groups", ["club_id"], name: "index_preference_groups_on_club_id", using: :btree

  create_table "preferences", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "preference_group_id", limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "products", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "sku",                limit: 255
    t.boolean  "recurrent",                      default: false
    t.integer  "stock",              limit: 4
    t.integer  "weight",             limit: 4
    t.integer  "club_id",            limit: 8
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "package",            limit: 255
    t.boolean  "allow_backorder",                default: false
    t.string   "cost_center",        limit: 255
    t.boolean  "is_visible",                     default: true
    t.datetime "deleted_at"
    t.string   "image_url",          limit: 255
    t.boolean  "alert_on_low_stock",             default: false
    t.boolean  "low_stock_alerted",              default: false
  end

  add_index "products", ["club_id"], name: "index_products_on_club_id", using: :btree
  add_index "products", ["sku"], name: "index_products_on_sku", using: :btree

  create_table "prospects", force: :cascade do |t|
    t.string   "first_name",                    limit: 255
    t.string   "last_name",                     limit: 255
    t.string   "address",                       limit: 255
    t.string   "city",                          limit: 255
    t.string   "state",                         limit: 255
    t.string   "zip",                           limit: 255
    t.string   "email",                         limit: 255
    t.string   "landing_url",                   limit: 255
    t.integer  "terms_of_membership_id",        limit: 8
    t.date     "birth_date"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.string   "visitor_id",                    limit: 255
    t.text     "preferences",                   limit: 65535
    t.string   "product_sku",                   limit: 255
    t.string   "utm_campaign",                  limit: 255
    t.string   "audience",                      limit: 255
    t.string   "ip_address",                    limit: 255
    t.string   "country",                       limit: 255
    t.string   "user_agent",                    limit: 255
    t.string   "referral_host",                 limit: 255
    t.text     "referral_parameters",           limit: 65535
    t.text     "cookie_value",                  limit: 65535
    t.boolean  "joint",                                       default: false
    t.integer  "phone_country_code",            limit: 4
    t.integer  "phone_area_code",               limit: 4
    t.integer  "phone_local_number",            limit: 4
    t.string   "type_of_phone_number",          limit: 255
    t.string   "gender",                        limit: 255
    t.boolean  "cookie_set"
    t.string   "referral_path",                 limit: 255
    t.string   "product_description",           limit: 255
    t.string   "campaign_code",                 limit: 255
    t.string   "utm_medium",                    limit: 255
    t.string   "campaign_description",          limit: 255
    t.string   "utm_content",                   limit: 255
    t.string   "uuid",                          limit: 36
    t.integer  "club_id",                       limit: 4
    t.string   "marketing_client_sync_result",  limit: 255
    t.integer  "email_quality",                 limit: 4,     default: 0
    t.string   "utm_source",                    limit: 255
    t.boolean  "need_sync_to_marketing_client",               default: false
    t.text     "error_messages",                limit: 65535
    t.integer  "campaign_id",                   limit: 4
  end

  add_index "prospects", ["campaign_id"], name: "index_prospects_on_campaign_id", using: :btree
  add_index "prospects", ["club_id"], name: "index_prospects_on_club_id", using: :btree
  add_index "prospects", ["created_at"], name: "index_created_at", using: :btree
  add_index "prospects", ["uuid"], name: "index_prospects_on_uuid", unique: true, using: :btree

  create_table "suspected_fulfillment_evidences", force: :cascade do |t|
    t.integer  "fulfillment_id",          limit: 4
    t.integer  "matched_fulfillment_id",  limit: 4
    t.integer  "match_age",               limit: 4
    t.boolean  "email_match"
    t.boolean  "full_name_match"
    t.boolean  "full_address_match"
    t.boolean  "full_phone_number_match"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suspected_fulfillment_evidences", ["fulfillment_id"], name: "index_suspected_fulfillment_evidences_on_fulfillment_id", using: :btree
  add_index "suspected_fulfillment_evidences", ["matched_fulfillment_id"], name: "index_suspected_fulfillment_evidences_on_matched_fulfillment_id", using: :btree

  create_table "terms_of_memberships", force: :cascade do |t|
    t.string   "name",                         limit: 255
    t.text     "description",                  limit: 65535
    t.integer  "club_id",                      limit: 8
    t.integer  "provisional_days",             limit: 4,                              default: 30
    t.boolean  "needs_enrollment_approval",                                           default: false
    t.decimal  "installment_amount",                         precision: 11, scale: 2, default: 0.0
    t.string   "installment_type",             limit: 255,                            default: "1.month"
    t.datetime "deleted_at"
    t.datetime "created_at",                                                                              null: false
    t.datetime "updated_at",                                                                              null: false
    t.integer  "downgrade_tom_id",             limit: 8
    t.string   "api_role",                     limit: 255
    t.integer  "agent_id",                     limit: 4
    t.decimal  "initial_fee",                                precision: 5,  scale: 2
    t.decimal  "trial_period_amount",                        precision: 5,  scale: 2
    t.boolean  "is_payment_expected",                                                 default: true
    t.integer  "installment_period",           limit: 4,                              default: 1
    t.integer  "subscription_limits",          limit: 4
    t.string   "if_cannot_bill",               limit: 255
    t.integer  "suspension_period",            limit: 4
    t.integer  "upgrade_tom_id",               limit: 4
    t.integer  "upgrade_tom_period",           limit: 4
    t.decimal  "initial_club_cash_amount",                   precision: 11, scale: 2, default: 0.0
    t.decimal  "club_cash_installment_amount",               precision: 11, scale: 2, default: 0.0
    t.boolean  "skip_first_club_cash",                                                default: false
  end

  add_index "terms_of_memberships", ["club_id"], name: "index_club_id", using: :btree

  create_table "transactions", force: :cascade do |t|
    t.integer  "terms_of_membership_id",           limit: 8
    t.integer  "payment_gateway_configuration_id", limit: 8
    t.string   "report_group",                     limit: 255
    t.string   "merchant_key",                     limit: 255
    t.string   "login",                            limit: 255
    t.string   "password",                         limit: 255
    t.string   "descriptor_name",                  limit: 255
    t.string   "descriptor_phone",                 limit: 255
    t.string   "gateway",                          limit: 255
    t.integer  "expire_month",                     limit: 4
    t.integer  "expire_year",                      limit: 4
    t.string   "transaction_type",                 limit: 255
    t.string   "invoice_number",                   limit: 255
    t.string   "first_name",                       limit: 255
    t.string   "last_name",                        limit: 255
    t.string   "phone_number",                     limit: 255
    t.string   "email",                            limit: 255
    t.string   "address",                          limit: 255
    t.string   "city",                             limit: 255
    t.string   "state",                            limit: 255
    t.string   "zip",                              limit: 255
    t.decimal  "amount",                                         precision: 11, scale: 2, default: 0.0
    t.integer  "decline_strategy_id",              limit: 8
    t.text     "response",                         limit: 65535
    t.string   "response_code",                    limit: 255
    t.string   "response_result",                  limit: 255
    t.string   "response_transaction_id",          limit: 255
    t.string   "response_auth_code",               limit: 255
    t.datetime "created_at",                                                                              null: false
    t.datetime "updated_at",                                                                              null: false
    t.integer  "credit_card_id",                   limit: 8
    t.decimal  "refunded_amount",                                precision: 11, scale: 2, default: 0.0
    t.string   "country",                          limit: 255
    t.integer  "membership_id",                    limit: 8
    t.string   "token",                            limit: 255
    t.string   "cc_type",                          limit: 255
    t.string   "last_digits",                      limit: 255
    t.integer  "user_id",                          limit: 8
    t.boolean  "success",                                                                 default: false
    t.integer  "operation_type",                   limit: 4
    t.integer  "club_id",                          limit: 4
  end

  add_index "transactions", ["club_id"], name: "index_transactions_on_club_id", using: :btree
  add_index "transactions", ["created_at"], name: "index_created_at", using: :btree
  add_index "transactions", ["membership_id"], name: "index_transactions_on_membership_id", using: :btree
  add_index "transactions", ["operation_type"], name: "index_transactions_on_operation_type", using: :btree
  add_index "transactions", ["response_transaction_id"], name: "index_response_transaction_id", using: :btree
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id", using: :btree

  create_table "transport_settings", force: :cascade do |t|
    t.integer  "club_id",    limit: 4
    t.integer  "transport",  limit: 4,     null: false
    t.text     "settings",   limit: 65535, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "transport_settings", ["club_id", "transport"], name: "index_transport_settings_on_club_id_and_transport", unique: true, using: :btree

  create_table "user_additional_data", force: :cascade do |t|
    t.integer  "club_id",    limit: 8
    t.string   "param",      limit: 255
    t.string   "value",      limit: 255
    t.integer  "user_id",    limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_notes", force: :cascade do |t|
    t.integer  "created_by_id",         limit: 4
    t.text     "description",           limit: 65535
    t.integer  "disposition_type_id",   limit: 4
    t.integer  "communication_type_id", limit: 4
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "user_id",               limit: 8
  end

  add_index "user_notes", ["created_by_id"], name: "index_created_by_id", using: :btree
  add_index "user_notes", ["user_id"], name: "index_member_id", using: :btree

  create_table "user_preferences", force: :cascade do |t|
    t.integer  "club_id",    limit: 8
    t.string   "param",      limit: 255
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "user_id",    limit: 8
  end

  add_index "user_preferences", ["user_id", "club_id", "param"], name: "index_user_preferences_on_user_id_and_club_id_and_param", using: :btree

  create_table "users", force: :cascade do |t|
    t.integer  "club_id",                             limit: 8,                                                     null: false
    t.string   "external_id",                         limit: 255
    t.string   "first_name",                          limit: 255
    t.string   "last_name",                           limit: 255
    t.string   "email",                               limit: 255,                                                   null: false
    t.string   "address",                             limit: 255
    t.string   "city",                                limit: 255
    t.string   "state",                               limit: 255
    t.string   "zip",                                 limit: 255
    t.string   "country",                             limit: 255
    t.string   "status",                              limit: 255,                            default: "none"
    t.datetime "bill_date"
    t.datetime "next_retry_bill_date"
    t.integer  "recycled_times",                      limit: 4,                              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "blacklisted",                                                                default: false
    t.integer  "member_group_type_id",                limit: 4
    t.datetime "member_since_date"
    t.string   "wrong_address",                       limit: 255
    t.string   "wrong_phone_number",                  limit: 255
    t.string   "api_id",                              limit: 255
    t.datetime "last_synced_at"
    t.text     "last_sync_error",                     limit: 65535
    t.decimal  "club_cash_amount",                                  precision: 11, scale: 2, default: 0.0
    t.datetime "club_cash_expire_date"
    t.date     "birth_date"
    t.text     "preferences",                         limit: 65535
    t.datetime "last_sync_error_at"
    t.string   "gender",                              limit: 1
    t.string   "type_of_phone_number",                limit: 255
    t.integer  "phone_country_code",                  limit: 4
    t.integer  "phone_area_code",                     limit: 4
    t.integer  "phone_local_number",                  limit: 4
    t.text     "autologin_url",                       limit: 65535
    t.integer  "current_membership_id",               limit: 8
    t.string   "sync_status",                         limit: 255,                            default: "not_synced"
    t.text     "additional_data",                     limit: 65535
    t.boolean  "manual_payment",                                                             default: false
    t.datetime "marketing_client_last_synced_at"
    t.string   "marketing_client_synced_status",      limit: 255,                            default: "not_synced"
    t.string   "marketing_client_last_sync_error",    limit: 255
    t.datetime "marketing_client_last_sync_error_at"
    t.integer  "email_quality",                       limit: 4,                              default: 0
    t.boolean  "need_sync_to_marketing_client",                                              default: false
    t.datetime "current_join_date"
    t.string   "marketing_client_id",                 limit: 255
    t.string   "stripe_id",                           limit: 255
    t.boolean  "testing_account",                                                            default: false
    t.date     "change_tom_date"
    t.text     "change_tom_attributes",               limit: 65535
    t.string   "slug",                                limit: 100
  end

  add_index "users", ["club_id", "api_id"], name: "api_id_UNIQUE", unique: true, using: :btree
  add_index "users", ["club_id", "email"], name: "email_UNIQUE", unique: true, using: :btree
  add_index "users", ["created_at"], name: "index_created_at", using: :btree
  add_index "users", ["current_membership_id"], name: "index_current_membership_id", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["need_sync_to_marketing_client", "club_id"], name: "index_users_on_need_sync_to_marketing_client_and_club_id", using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", using: :btree

  add_foreign_key "campaign_products", "campaigns"
  add_foreign_key "campaign_products", "products"
end
