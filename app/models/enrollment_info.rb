class EnrollmentInfo < ActiveRecord::Base
  belongs_to :member
  belongs_to :prospect

  serialize :preferences, JSON

  attr_accessible :member_id, :prospect_id, :enrollment_amount, :product_sku, :product_description, :mega_channel,
                  :marketing_code, :fulfillment_code, :ip_address, :user_agent, :referral_host,
                  :referral_parameters, :referral_path, :user_id, :landing_url, :terms_of_membership_id,
                  :preferences, :cookie_value, :cookie_set, :campaign_medium, :campaign_description,
                  :campaign_medium_version, :is_joint

  private
    def update_enrollment_info_by_hash(params)
      self.product_sku = params[:product_sku]
      #TODO: complete with each param we get from API hash
    end

end