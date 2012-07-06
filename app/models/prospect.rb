class Prospect < ActiveRecord::Base
  include Extensions::UUID

  has_many :enrollment_infos

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email, :phone_number, :birth_date,
                  :preferences, :mega_chanel, :ip_address, :referral_host, :referral_parameters, :cookie_value,
                  :marketing_code, :product_sku, :user_id, :landing_url, :mega_channel, :user_agent, :joint


end
