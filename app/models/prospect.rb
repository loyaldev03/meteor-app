class Prospect < ActiveRecord::Base
  include Extensions::UUID

  has_one :membership
  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :campaign

  serialize :preferences, JSON
  serialize :referral_parameters, JSON
  serialize :error_messages, JSON

  before_create :set_marketing_client_sync_as_needed
  before_create :calculate_visitor_id

  # attr_accessible :first_name, :last_name, :address, :city, :state, :zip, :email,:phone_country_code,
  #           :phone_area_code ,:phone_local_number, :birth_date, :preferences, :gender,
  #           :ip_address, :referral_host, :referral_parameters, :cookie_value,:marketing_code,
  #           :product_sku, :visitor_id, :landing_url, :mega_channel, :user_agent, :joint,
  #           :campaign_medium, :campaign_description, :campaign_medium_version , :terms_of_membership_id,
  #           :country, :type_of_phone_number, :fulfillment_code, :referral_path, :cookie_set, :product_description, :source,
  #           :need_sync_to_marketing_client

  def full_phone_number
    "+#{self.phone_country_code} (#{self.phone_area_code}) #{self.phone_local_number}"
  end

  def marketing_tool_sync
    case(club.marketing_tool_client)
    when 'exact_target'
      exact_target_after_create_sync_to_remote_domain if defined?(SacExactTarget::ProspectModel) and exact_target_prospect
    when 'mailchimp_mandrill'
      Mailchimp::ProspectSynchronizationJob.perform_later(prospect_id: self.id) if defined?(SacMailchimp::ProspectModel) and mailchimp_prospect
    end
  end

  def skip_sync!
    @skip_sync = true
  end

  def campaign=(campaign)
    self.audience               = campaign.audience
    self.utm_medium             = campaign.utm_medium
    self.utm_campaign           = campaign.campaign_type
    self.utm_content            = campaign.utm_content
    self.campaign_code          = campaign.campaign_code
    self.utm_source             = campaign.transport
    self.landing_url            = campaign.landing_url
    self.terms_of_membership_id = campaign.terms_of_membership_id
    self.club_id                = campaign.club_id
    self.campaign_id            = campaign.id
  end

  def phone
    [self.phone_country_code, self.phone_area_code, self.phone_local_number].join('')
  end

  def self.where_token(token)
    id, created_at = Base64.urlsafe_decode64(token).split(',')
    Prospect.find_by(id: id, created_at: Time.parse(created_at).utc)
  rescue ArgumentError => e
    Auditory.report_issue('Prospect:where_token', e, token: token)
    return nil
  end

  def token
    Base64.urlsafe_encode64("#{id}, #{created_at.utc}")
  end

  private

  def after_marketing_tool_sync
    marketing_tool_sync unless @skip_sync
  end

  def set_marketing_client_sync_as_needed
    self.need_sync_to_marketing_client = true if (defined?(SacExactTarget::ProspectModel) and not self.email.blank?) or (defined?(SacMailchimp::ProspectModel) and not self.email.blank?)
  end

  def calculate_visitor_id
    self.visitor_id = Digest::MD5.hexdigest(self.ip_address + self.user_agent)
  end
end
