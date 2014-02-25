class Prospect < ActiveRecord::Base
  include Extensions::UUID

  has_many :enrollment_infos
  belongs_to :terms_of_membership
  belongs_to :club

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email,:phone_country_code, 
   				  :phone_area_code ,:phone_local_number, :birth_date, :preferences, :gender, 
   				  :ip_address, :referral_host, :referral_parameters, :cookie_value,:marketing_code, 
            :product_sku, :user_id, :landing_url, :mega_channel, :user_agent, :joint,
            :campaign_medium, :campaign_description, :campaign_medium_version , :terms_of_membership_id, 
            :country, :type_of_phone_number, :fulfillment_code, :referral_path, :cookie_set, :product_description, :source


  def full_phone_number
    "(#{self.phone_country_code}) #{self.phone_area_code} - #{self.phone_local_number}"
  end

  def marketing_tool_sync_without_dj
    self.exact_target_after_create_sync_to_remote_domain if defined?(SacExactTarget::ProspectModel)
    self.pardot_after_create_sync_to_remote_domain if defined?(Pardot::ProspectModel)
  end

  def marketing_tool_sync
    marketing_tool_sync_without_dj
  end
  handle_asynchronously :marketing_tool_sync, :queue => :exact_target_sync

  def skip_sync!
     @skip_sync = true
  end
 
  private 
 
    def after_marketing_tool_sync
      marketing_tool_sync unless @skip_sync
    end
end
