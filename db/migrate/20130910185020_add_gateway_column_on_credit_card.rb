class AddGatewayColumnOnCreditCard < ActiveRecord::Migration
  def change
    add_column :credit_cards, :gateway, :string
  end
end
