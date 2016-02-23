class AddEnrollmentInfosColumnsOnMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :enrollment_amount, :decimal, :precision => 11, :scale => 2, :default => 0.0
    add_column :memberships, :product_sku, :text
    add_column :memberships, :product_id, :integer
    add_column :memberships, :product_description, :text
    add_column :memberships, :mega_channel, :string
    add_column :memberships, :marketing_code, :string
    add_column :memberships, :fulfillment_code, :string
    add_column :memberships, :ip_address, :string
    add_column :memberships, :user_agent, :string
    add_column :memberships, :referral_host, :string
    add_column :memberships, :referral_parameters, :text
    add_column :memberships, :referral_path, :string
    add_column :memberships, :visitor_id, :string
    add_column :memberships, :landing_url, :string
    add_column :memberships, :preferences, :text
    add_column :memberships, :cookie_value, :string
    add_column :memberships, :cookie_set, :boolean
    add_column :memberships, :campaign_medium, :text
    add_column :memberships, :campaign_description, :text
    add_column :memberships, :campaign_medium_version, :text
    add_column :memberships, :joint, :boolean
    add_column :memberships, :prospect_id, :integer
    add_column :memberships, :source, :string

    add_index :memberships, :prospect_id
    add_index :memberships, :product_id
  end
end
