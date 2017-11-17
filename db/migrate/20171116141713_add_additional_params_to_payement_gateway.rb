class AddAdditionalParamsToPayementGateway < ActiveRecord::Migration
  def change
    add_column :payment_gateway_configurations, :additional_attributes, :text
  end
end
