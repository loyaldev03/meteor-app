class CreateCommunications < ActiveRecord::Migration
  def change
    create_table :communications do |t|
      t.string :member_id, :limit => 36
      t.string :template_name
      t.string :email
      t.datetime :run_at
      t.string :client 
      t.string :external_id 
      t.string :template_type
      t.boolean :sent
      t.text :request
      t.text :response
      t.timestamps
    end
  end
end
