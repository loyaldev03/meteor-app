class CreateFulfillments < ActiveRecord::Migration
  def change
    create_table :fulfillments do |t|
      t.string :member_id, :limit => 36
      t.string :product
      t.datetime :assigned_at # The day this fulfillment is assigned to our member.
      t.datetime :delivered_at # The day CS or our delivery provider send the fulfillment.
      t.datetime :renewable_at
      t.string :status
      t.timestamps
    end
  end
end
