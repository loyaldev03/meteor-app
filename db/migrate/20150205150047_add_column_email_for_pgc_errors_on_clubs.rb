class AddColumnEmailForPgcErrorsOnClubs < ActiveRecord::Migration
  def up
  	add_column :clubs, :payment_gateway_errors_email, :string
  end

  def down
  	remove_column :clubs; :payment_gateway_errors_email
  end
end
