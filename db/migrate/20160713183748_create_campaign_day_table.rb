class CreateCampaignDayTable < ActiveRecord::Migration
  def change
    create_table :campaign_days do |t|
      t.references  :campaign
      t.date        :date
      t.decimal     :spent
      t.integer     :reached
      t.integer     :converted
      t.integer     :meta, default: 0

      t.timestamps null: false
    end

    add_index :campaign_days, [:campaign_id, :date], :unique => true
  end
end
