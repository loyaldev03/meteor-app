#
# api_type column should have Drupal::Member or Wordpress::Member
#
class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :terms_of_memberships
  has_many :users
  has_many :fulfillments
  has_many :prospects
  has_many :payment_gateway_configurations
  has_many :member_group_types
  has_many :products
  has_many :club_roles
  has_many :agents, -> {uniq}, through: :club_roles
  has_many :fulfillment_files
  has_many :disposition_types
  has_many :campaigns
  has_many :transport_settings
  has_many :preference_groups
  belongs_to :api_domain,
    class_name:  'Domain',
    foreign_key: 'drupal_domain_id'

  acts_as_paranoid

  before_validation :complete_urls
  before_save :not_allow_multiple_mailchimp_clients_with_same_list_id
  after_create :add_default_member_groups, :add_default_disposition_type
  after_update :resync_with_merketing_tool_process

  validates :partner_id, :cs_phone_number, :cs_email, presence: true
  validates :name, presence: true, uniqueness: true
  validates :member_banner_url, :non_member_banner_url, :member_landing_url, :non_member_landing_url, :checkout_url, :unavailable_campaign_url,
            format: /(^$)|(^(http|https):\/\/([\w]+:\w+@)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  validates :privacy_policy_url, :twitter_url, :facebook_url, format: /(^$)|(^(http|https):\/\/([\w]+:\w+@)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  validate :payment_gateway_errors_email_is_well_formated
  validates :cs_email, format: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/
  validates :fulfillment_tracking_prefix, length: { maximum: 1 }

  scope :exact_target_related, lambda { where("marketing_tool_client = 'exact_target' AND (marketing_tool_attributes like '%et_business_unit%' AND marketing_tool_attributes not like '%\"et_business_unit\":\"\"%') AND (marketing_tool_attributes like '%et_prospect_list%'AND marketing_tool_attributes not like '%\"et_prospect_list\":\"\"%') AND (marketing_tool_attributes like '%et_members_list%' AND marketing_tool_attributes not like '%\"et_members_list\":\"\"%') AND (marketing_tool_attributes like '%et_username%' AND marketing_tool_attributes not like '%\"et_username\":\"\"%') AND ( marketing_tool_attributes like '%et_password%' AND marketing_tool_attributes not like '%\"et_password\":\"\"%') AND (marketing_tool_attributes like '%et_endpoint%' AND marketing_tool_attributes not like '%\"et_endpoint\":\"\"%')") }
  scope :mailchimp_related, lambda { where("marketing_tool_client = 'mailchimp_mandrill' AND (marketing_tool_attributes like '%mailchimp_api_key%' AND marketing_tool_attributes not like '%\"mailchimp_api_key\":\"\"%') AND (marketing_tool_attributes like '%mailchimp_list_id%'AND marketing_tool_attributes not like '%\"mailchimp_list_id\":\"\"%')") }
  scope :is_enabled, -> { where(billing_enable: true) }

  scope :with_drupal_configured, -> { where(api_type: 'Drupal::Member') } 
  scope :with_spree_configured, -> { where(api_type: 'Spree::Member') } 

  has_attached_file :logo, path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                           url: "/system/:attachment/:id/:style/:filename",
                           styles: { header: "120x40", thumb: "100x100#", small: "150x150>" }
  has_attached_file :header_image, styles: { thumb: '300x' }
  has_attached_file :favicon
  has_attached_file :appletouch_icon, styles: { thumb: '50x' }
  has_attached_file :result_pages_image, styles: { thumb: '50x' }
  # This validation MUST be placed after the has_attachment declaration. Otherwise, it will fail https://github.com/thoughtbot/paperclip/issues/1340
  validates_attachment_content_type :header_image,:result_pages_image,
                                    content_type: ['image/jpg', 'image/jpeg', 'image/png']
  validates_attachment_content_type :favicon,
                                    content_type: ['image/x-icon', 'image/vnd.microsoft.icon']
  validates_attachment_content_type :appletouch_icon, content_type: 'image/png'

  # marketing_tool_attributes possible keys:
  # Pardot : pardot_email, pardot_user_key, pardot_password
  # Exact Target : et_bussines_unit, et_prospect_list, et_members_list
  serialize :marketing_tool_attributes, JSON

  def test_connection_to_api!
    if self.sync?
      conn = drupal({ logout: true })
      res = conn.get('/api/user/').body
    else
      raise "Drupal configuration is not completed."
    end
  end

  def full_name
    [ partner.name, name ].join(' ')
  end

  def self.datatable_columns
    ['id', 'name', 'description', 'members_count', 'billing_enable' ]
  end

  def sync?
    [self.api_type, self.api_username, self.api_password].none?(&:blank?)
  end

  def exact_target_client?
    self.marketing_tool_client == 'exact_target'
  end

  def mailchimp_mandrill_client?
    self.marketing_tool_client == 'mailchimp_mandrill'
  end

  def pardot_sync?
    self.marketing_tool_attributes and
    [
      self.marketing_tool_attributes['pardot_email'],
      self.marketing_tool_attributes['pardot_password'],
      self.marketing_tool_attributes['pardot_user_key']
    ].none?(&:blank?)
  end

  def exact_target_sync?
    if self.marketing_tool_attributes
      attributes = [
        self.marketing_tool_attributes['et_business_unit'],
        self.marketing_tool_attributes['et_prospect_list'],
        self.marketing_tool_attributes['et_members_list'],
        self.marketing_tool_attributes['et_username'],
        self.marketing_tool_attributes['et_password'],
        self.marketing_tool_attributes['et_endpoint']
      ]
      attributes << self.marketing_tool_attributes['club_id_for_test'] unless Rails.env.production?
      attributes.none?(&:blank?)
    else
      false
    end
  end

  def mailchimp_sync?
    self.marketing_tool_attributes and
    [
      self.marketing_tool_attributes['mailchimp_api_key'],
      self.marketing_tool_attributes['mailchimp_list_id']
    ].none?(&:blank?)
  end

  def mandrill_configured?
    self.marketing_tool_attributes and
    [
      self.marketing_tool_attributes['mandrill_api_key']
    ].none?(&:blank?)
  end

  def marketing_tool_correctly_configured?
    case marketing_tool_client
    when "exact_target"
      exact_target_sync?
    when "pardot"
      pardot_sync?
    when "mailchimp_mandrill"
      mailchimp_sync? and mandrill_configured?
    when "action_mailer"
      true
    end
  end

  def payment_gateway_configuration
    payment_gateway_configurations.first
  end
  
  def is_cms_configured?
    (is_drupal? or is_spree?)
  end
  # Improvements #25771 - Club cash transactions will be managed by Drupal User Points plugin.
  def is_drupal?
    api_type == 'Drupal::Member'
  end
  
  def is_spree?
    api_type == 'Spree::Member'
  end

  def allow_club_cash_transaction?
    club_cash_enable and billing_enable
  end

  def use_pgc_authorize_net?
    pgc = self.payment_gateway_configurations.first
    not pgc.nil? and pgc.authorize_net?
  end

  def resync_users_and_prospects
    Clubs::ResyncUsersAndProspectsJob.perform_later(club_id: self.id)
  end

  def available_transport_settings
    used_transports = transport_settings.select(:transport).map(&:transport)
    TransportSetting.transports_i18n.invert.select{|k,v| !used_transports.include?(v)}
  end

  def has_store_configured?
    @transport_settings ||= transport_settings.store_spree.first
    @transport_settings.present?
  end

  def store_url
    store_transport_setting = self.transport_settings.store_spree.first
    store_transport_setting.nil? ? '' : store_transport_setting.settings['url']
  end

  private
    def add_default_member_groups
      ['VIP', 'Celebrity', 'Notable', 'Charter Member'].each do |name|
        m = MemberGroupType.new
        m.name= name
        m.club_id = self.id
        m.save
      end
    end

    def add_default_disposition_type
      ['Website Question', 'Technical Support', 'Benefits Question', 'Pre-Bill Cancellation',
      'Pre-Bill Save', 'Product Questions', 'Deals and Discounts', 'VIP Question', 'Club Cash Question',
      'Local Chapter Question', "Postbill Cancellation", "Postbill Save", "Confirm"].each do |name|
        d = DispositionType.new
        d.name = name
        d.club_id = self.id
        d.save
      end
    end
    
    def complete_urls
      [:member_banner_url, :non_member_banner_url, :member_landing_url, :non_member_landing_url].each do |field|
        if self.changes.include? field
          url = self.send field
          if not url.blank? and not url.match(/^(http|https):\/\//)
            self.send field.to_s+"=", "http://"+url
          end
        end
      end
    end

    def resync_with_merketing_tool_process
      if self.changes.include? :marketing_tool_client
        unless ['action_mailer', ''].include?(self.changes[:marketing_tool_client].last)
          resync_users_and_prospects
        end
      end
    end

    def not_allow_multiple_mailchimp_clients_with_same_list_id
      if self.mailchimp_mandrill_client? and self.changes.include?(:marketing_tool_attributes) and not self.changes['marketing_tool_attributes'].last["mailchimp_list_id"].blank?
        mailchimp_list_id = self.changes['marketing_tool_attributes'].last["mailchimp_list_id"]
        already_configured = Club.where("marketing_tool_client = 'mailchimp_mandrill' AND marketing_tool_attributes like ? and id != ?", "%#{mailchimp_list_id}%", id.to_i)
        unless already_configured.empty?
          already_configured.each do |club|
            if club.marketing_tool_attributes["mailchimp_list_id"] == mailchimp_list_id
              errors[:marketing_tool_attributes] << "mailchimp_list_id;List ID #{mailchimp_list_id} is already configured in another club."
              return false
            end
          end
        end
      end
    end

    def payment_gateway_errors_email_is_well_formated
      self.payment_gateway_errors_email.to_s.split(",").each do |email|
        unless email.strip.match(/^[0-9a-zA-Z\-_]([-_\.]?[+?]?[0-9a-zA-Z\-_])*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/)
          errors[:payment_gateway_errors_email] << "Invalid information. '#{email}' is an invalid email."
        end
      end
    end
end
