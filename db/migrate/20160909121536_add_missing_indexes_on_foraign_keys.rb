class AddMissingIndexesOnForaignKeys < ActiveRecord::Migration
  def change
    add_index :club_roles, :club_id 
    add_index :domains, :partner_id
    add_index :enumerations, :club_id
    add_index :fulfillment_files, :agent_id
    add_index :fulfillment_files, :club_id
    add_index :fulfillment_files_fulfillments, :fulfillment_id
    add_index :memberships, :created_by_id
    add_index :operations, :club_id
    add_index :operations, :created_by_id
    add_index :prospects, :club_id
  end
end
