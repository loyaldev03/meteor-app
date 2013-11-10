class RemoveModeFromTomAndPgc < ActiveRecord::Migration
  def up
  	remove_column :terms_of_memberships, :mode
  	remove_column :payment_gateway_configurations, :mode
  end

  def down
   	add_column :terms_of_memberships, :mode, :string
  	add_column :payment_gateway_configurations, :mode, :string
  end
end
