class CreateFulfillmentFiles < ActiveRecord::Migration
  def change
    create_table :fulfillment_files do |t|
      t.integer :agent_id
      t.integer :club_id
      t.date :initial_date
      t.date :end_date
      t.boolean :all_times, :default => false
      t.string :product
      t.string :status
      t.timestamps
    end
    create_table :fulfillment_files_fulfillments, {:id => false} do |t|
      t.integer :fulfillment_id
      t.integer :fulfillment_file_id
    end
  end
end
