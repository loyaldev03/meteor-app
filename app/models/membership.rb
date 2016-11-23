class Membership < ActiveRecord::Base
  belongs_to :terms_of_membership
  belongs_to :user
  belongs_to :created_by, class_name: 'Agent', foreign_key: 'created_by_id'
  belongs_to :product
  has_many :transactions

  serialize :preferences, JSON

  # validates :terms_of_membership, :presence => true
  # validates :member, :presence => true
  
  after_create :audit_creation_and_assign_default_created_by

  CS_UTM_CAMPAIGN = 'other'
  CS_UTM_MEDIUM = 'phone'
  CS_UTM_MEDIUM_API = 'api'
  CS_UTM_MEDIUM_UPGRADE = 'upgrade'
  CS_UTM_MEDIUM_DOWNGRADE = 'downgrade'
  CS_CAMPAIGN_DESCRIPTION = 'CS Join'

  def self.datatable_columns
    ['id', 'status', 'tom', 'join_date', 'cancel_date']
  end

  def cancel_because_of_membership_change
    self.update_attributes cancel_date: Time.zone.now, status: 'lapsed'
  end

  def update_membership_info_by_hash(params)
    unless params.nil?
      self.product_description = params[:product_description]
      self.utm_campaign = params[:utm_campaign].downcase if params[:utm_campaign]
      self.audience = params[:audience].downcase if params[:audience]
      self.campaign_code = params[:campaign_id].downcase if params[:campaign_id]
      self.ip_address = params[:ip_address]
      self.product_sku = params[:product_sku]
      self.user_agent = params[:user_agent].truncate(255) if params[:user_agent]
      self.referral_host = params[:referral_host]
      self.referral_parameters = params[:referral_parameters]
      self.referral_path = params[:referral_path].truncate(255) if params[:referral_path]
      self.visitor_id = params[:visitor_id]
      self.landing_url = params[:landing_url].downcase if params[:landing_url]
      self.preferences = params[:preferences]
      self.cookie_value = params[:cookie_value]
      self.cookie_set = params[:cookie_set]
      self.utm_source = params[:utm_source]
      self.utm_medium = params[:utm_medium].downcase if params[:utm_medium]
      self.campaign_description = params[:campaign_description]
      self.utm_content = params[:utm_content].downcase if params[:utm_content]
      self.prospect_id = params[:prospect_id]
      self.joint = params[:joint]
    end
  end

  private
    def audit_creation_and_assign_default_created_by
      self.created_by ||= Agent.find_by(email: 'batch@xagax.com')
      Auditory.audit(created_by, self, "New Membership record created.", self.user, Settings.operation_types.enrollment)
    end
end
