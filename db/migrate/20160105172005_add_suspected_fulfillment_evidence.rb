class AddSuspectedFulfillmentEvidence < ActiveRecord::Migration
  create_table :suspected_fulfillment_evidences, :force => true do |t|
    t.integer   :fulfillment_id
    t.integer   :matched_fulfillment_id
    t.integer   :match_age
    t.boolean   :email_match
    t.boolean   :full_name_match
    t.boolean   :full_address_match
    t.boolean   :full_phone_number_match
    t.timestamps
  end
  add_index :suspected_fulfillment_evidences, :fulfillment_id
  add_index :suspected_fulfillment_evidences, :matched_fulfillment_id
end