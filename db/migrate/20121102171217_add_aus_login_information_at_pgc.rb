class AddAusLoginInformationAtPgc < ActiveRecord::Migration
  def up
    add_column :payment_gateway_configurations, :aus_login, :string
    add_column :payment_gateway_configurations, :aus_password, :string
  end

  def down
    remove_column :payment_gateway_configurations, :aus_login
    remove_column :payment_gateway_configurations, :aus_password
  end
end
