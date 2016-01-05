class EnrollmentInfo < ActiveRecord::Base
  belongs_to :user
  belongs_to :membership
  belongs_to :prospect

  serialize :preferences, JSON

  attr_accessible :user_id, :prospect_id, :enrollment_amount, :product_sku, :product_description, :mega_channel,
                  :marketing_code, :fulfillment_code, :ip_address, :user_agent, :referral_host,
                  :referral_parameters, :referral_path, :visitor_id, :landing_url, :terms_of_membership_id,
                  :preferences, :cookie_value, :cookie_set, :campaign_medium, :campaign_description,
                  :campaign_medium_version, :joint

  scope :current, -> { order("created_at DESC").limit(1) }

  after_create :audit_enrollment

  CS_MEGA_CHANNEL = 'other'
  CS_CAMPAIGN_MEDIUM = 'phone'
  CS_CAMPAIGN_DESCRIPTION = 'CS Join'

  # Method to update every enrollment_info field with the hash of information we recieve when enrolling a user.
  #
  def update_enrollment_info_by_hash(params)
    unless params.nil?
      self.product_sku = params[:product_sku].upcase if params[:product_sku] 
      self.product_description = params[:product_description]
      self.mega_channel = params[:mega_channel].downcase if params[:mega_channel]
      self.marketing_code = params[:marketing_code].downcase if params[:marketing_code]
      self.fulfillment_code = params[:fulfillment_code].downcase if params[:fulfillment_code]
      self.ip_address = params[:ip_address]
      self.user_agent = params[:user_agent]
      self.referral_host = params[:referral_host]
      self.referral_parameters = params[:referral_parameters]
      self.referral_path = params[:referral_path]
      self.visitor_id = params[:visitor_id]
      self.landing_url = params[:landing_url].downcase if params[:landing_url]
      self.preferences = params[:preferences]
      self.cookie_value = params[:cookie_value]
      self.cookie_set = params[:cookie_set]
      self.source = params[:source]
      self.campaign_medium = params[:campaign_medium].downcase if params[:campaign_medium]
      self.campaign_description = params[:campaign_description]
      self.campaign_medium_version = params[:campaign_medium_version].downcase if params[:campaign_medium_version]
      self.prospect_id = params[:prospect_id]
      self.joint = params[:joint]
    end
  end

  private
    def audit_enrollment
      Auditory.audit(self.user.current_membership.created_by, self, "New Enrollment information record created.", self.user, Settings.operation_types.enrollment)
    end
end
