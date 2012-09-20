class AddRenewedFlagInFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :renewed, :boolean, :default => false
  end
end
