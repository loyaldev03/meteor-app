class Prospect < ActiveRecord::Base
  include Extensions::UUID

  has_many :enrollment_infos

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  before_create :set_cohort

  attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email,:phone_country_code, 
   				  :phone_area_code ,:phone_local_number, :birth_date, :preferences, 
   				  :ip_address, :referral_host, :referral_parameters, :cookie_value,:marketing_code, 
            :product_sku, :user_id, :landing_url, :mega_channel, :user_agent, :joint,
            :campaign_medium, :campaign_description, :campaign_medium_version

  private 
    def set_cohort
      today = Time.zone.now    
      cohort = [ today.year.to_s, today.month.to_s, mega_channel.to_s, campaign_medium.to_s ].join('-')
    end
end
