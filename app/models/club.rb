#
# api_type column should have Drupal::Member or Wordpress::Member
#
class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :terms_of_memberships
  has_many :members
  has_many :fulfillments
  has_many :prospects
  has_many :payment_gateway_configurations
  has_many :member_group_types
  has_many :products
  has_many :club_roles
  has_many :agents,
    through: :club_roles,
    uniq: true
  has_many :fulfillment_files
  has_many :disposition_types

  belongs_to :api_domain,
    class_name:  'Domain',
    foreign_key: 'drupal_domain_id'

  attr_accessible :description, :name, :logo, :drupal_domain_id, :theme, :requires_external_id,
    :api_type, :api_username, :api_password, :time_zone, :pardot_email, :pardot_password, :pardot_user_key,
    :cs_phone_number, :family_memberships_allowed, :club_cash_enable, :member_banner_url, :non_member_banner_url,
    :member_landing_url, :non_member_landing_url

  acts_as_paranoid

  after_create :add_default_member_groups, :add_default_product, :add_default_disposition_type
  after_update :resync_with_merketing_tool_process

  validates :partner_id, :cs_phone_number, :presence => true
  validates :name, :presence => true, :uniqueness => true
  validates :member_banner_url, :non_member_banner_url, :member_landing_url, :non_member_landing_url,
            :format =>  /(^$)|(^(http|https):\/\/([\w]+:\w+@)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix

  scope :exact_target_related, lambda { where("marketing_tool_attributes like '%et_business_unit%' AND marketing_tool_attributes like '%et_prospect_list%' AND marketing_tool_attributes like '%et_members_list%' ") }

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :styles => { :header => "120x40", :thumb => "100x100#", :small  => "150x150>" }

  before_validation :complete_urls

  DEFAULT_PRODUCT = ['KIT-CARD']

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
    ['id', 'name', 'description' ]
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
    self.marketing_tool_attributes and 
    [ 
      self.marketing_tool_attributes['et_business_unit'], 
      self.marketing_tool_attributes['et_prospect_list'], 
      self.marketing_tool_attributes['et_members_list'],
      self.marketing_tool_attributes['et_username'],
      self.marketing_tool_attributes['et_password']
    ].none?(&:blank?)
  end

  def payment_gateway_configuration
    payment_gateway_configurations.first
  end

  # Improvements #25771 - Club cash transactions will be managed by Drupal User Points plugin. 
  def is_not_drupal?
    api_type != 'Drupal::Member'
  end

  def allow_club_cash_transaction?
    club_cash_enable
  end

  def use_pgc_authorize_net?
    pgc = self.payment_gateway_configurations.first
    not pgc.nil? and pgc.authorize_net?
  end

  def resync_members_and_prospects
    subscribers = self.members+self.prospects
    if subscribers.count > Settings.maximum_number_of_subscribers_to_automatically_resync
      Auditory.report_club_changed_marketing_client(self, subscribers)
    end
    subscribers.each do |subscriber|
      subscribers.update_attribute :need_sync_to_marketing_client, 1
    end
  end
  handle_asynchronously :resync_members_and_prospects, :queue => :generic_queue


  private
    def add_default_member_groups
      ['VIP', 'Celebrity', 'Notable', 'Charter Member'].each do |name|
        m = MemberGroupType.new
        m.name= name
        m.club_id = self.id
        m.save
      end
    end

    def add_default_product
      Club::DEFAULT_PRODUCT.each do |sku|
        p = Product.new 
        p.sku = sku
        p.package = sku
        p.name = sku
        p.stock = 100
        p.recurrent = true
        p.allow_backorder = true
        p.club_id = self.id
        p.save
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
          resync_members_and_prospects 
        end
      end
    end
end
