class AddEnrollmentInformationIntoProspects < ActiveRecord::Migration
  def change
    add_column :prospects, :cookie_set, :boolean
    add_column :prospects, :referral_path, :string
    add_column :prospects, :product_description, :text
    add_column :prospects, :fulfillment_code, :string
    add_column :prospects, :campaign_medium, :text
    add_column :prospects, :campaign_description, :text
    add_column :prospects, :campaign_medium_version, :integer
  end
end
