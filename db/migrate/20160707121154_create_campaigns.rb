class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string      :name
      t.decimal     :enrollment_price, precision: 11, scale: 2, default: 0.0
      t.date        :initial_date
      t.date        :finish_date
      t.integer     :campaign_type
      t.integer     :transport
      t.string      :campaign_medium
      t.string      :campaign_medium_version
      t.string      :marketing_code
      t.string      :fulfillment_code

      t.references  :club
      t.references  :terms_of_membership
      t.timestamps  null: false
    end
  end
end
