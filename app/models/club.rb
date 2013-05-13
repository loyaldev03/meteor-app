#
# api_type column should have Drupal::Member or Wordpress::Member
#
class Club < ActiveRecord::Base
  belongs_to :partner
  has_many :domains
  has_many :terms_of_memberships
  has_many :members
  has_many :prospects
  has_many :payment_gateway_configurations
  has_many :member_group_types
  has_many :products
  has_many :club_roles
  has_many :agents,
    through: :club_roles,
    uniq: true
  has_many :fulfillment_files

  belongs_to :api_domain,
    class_name:  'Domain',
    foreign_key: 'drupal_domain_id'

  attr_accessible :description, :name, :logo, :drupal_domain_id, :theme, :requires_external_id,
    :api_type, :api_username, :api_password, :time_zone, :pardot_email, :pardot_password, :pardot_user_key,
    :cs_phone_number, :family_memberships_allowed, :club_cash_enable

  acts_as_paranoid

  after_create :add_default_member_groups, :add_default_product, :add_default_disposition_type

  validates :partner_id, :cs_phone_number, :presence => true
  validates :name, :presence => true, :uniqueness => true

  has_attached_file :logo, :path => ":rails_root/public/system/:attachment/:id/:style/:filename", 
                           :url => "/system/:attachment/:id/:style/:filename",
                           :styles => { :header => "120x40", :thumb => "100x100#", :small  => "150x150>" }

  DEFAULT_PRODUCT = ['KIT-CARD']

  def full_name
    [ partner.name, name ].join(' ')
  end

  def self.datatable_columns
    ['id', 'name', 'description' ]
  end

  def sync?
    [self.api_type, self.api_username, self.api_password].none?(&:blank?)
  end

  def pardot_sync?
    [self.pardot_email, self.pardot_password, self.pardot_user_key].none?(&:blank?)
  end

  # Improvements #25771 - Club cash transactions will be managed by Drupal User Points plugin. 
  def club_cash_transactions_enabled
    api_type != 'Drupal::Member'
  end

  def allow_club_cash_transaction?
    club_cash_enable
  end

  def use_pgc_authorize_net?
    pgc = self.payment_gateway_configurations.first
    not pgc.nil? and pgc.gateway == 'authorize_net'
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
end
