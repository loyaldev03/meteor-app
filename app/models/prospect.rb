class Prospect < ActiveRecord::Base
  # include Extensions::UUID
  include Extensions::SerializeJson

  serialize_json :preferences,
    :referral_parameters,
    :mega_channel

  attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email, :phone_number, :birth_date,
                  :preferences, :mega_chanel, :ip_address, :referral_host, :referral_parameters, :cookie_value,
                  :reporting_code, :product_id, :user_id, :url_landing, :mega_channel, :user_agent, :joint


end
