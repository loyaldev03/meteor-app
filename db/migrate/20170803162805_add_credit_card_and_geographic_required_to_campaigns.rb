class AddCreditCardAndGeographicRequiredToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :credit_card_and_geographic_required, :boolean, default: true
    add_column :clubs, :thank_you_page_content_when_no_cc_required, :text
  end
end
