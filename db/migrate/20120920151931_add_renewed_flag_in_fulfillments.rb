class AddRenewedFlagInFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :renewed, :default => false
  end
end
