class CreateCommunications < ActiveRecord::Migration
  def change
    create_table :communications do |t|
      t.string :member_id, :limit => 36
      t.string :template_name
      t.string :email
      t.datetime :scheduled_at
      t.datetime :processed_at
      t.string :client 
      t.string :external_attributes 
      t.string :template_type
      t.boolean :sent_success
      t.text :request
      t.text :response
      t.timestamps
    end
  end
end
