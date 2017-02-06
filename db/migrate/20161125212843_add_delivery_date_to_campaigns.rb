class AddDeliveryDateToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :delivery_date, :string, default: '3 - 5 weeks from date ordered'
  end
end
