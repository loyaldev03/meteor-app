class TermsOfMembership < ActiveRecord::Base
  attr_accessible :needs_enrollment_approval, :provisional_days, 
    :installment_amount, :description, :installment_type, :club, :name, :initial_club_cash_amount, 
    :club_cash_installment_amount, :skip_first_club_cash

  belongs_to :club
  has_many :transactions
  has_many :memberships
  has_many :prospects
  has_many :email_templates, :dependent => :destroy
  belongs_to :downgrade_tom, :class_name => 'TermsOfMembership', :foreign_key => 'downgrade_tom_id'
  belongs_to :upgrade_tom, :class_name => 'TermsOfMembership', :foreign_key => 'upgrade_tom_id'
  belongs_to :agent

  acts_as_paranoid

  after_create :setup_default_email_templates

  validates :name, :presence => true, :uniqueness => { :scope => :club_id }
  #validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :installment_period, :numericality => { :greater_than_or_equal_to => 1 }, if: Proc.new{ |tom| tom.is_payment_expected }
  validates :provisional_days, :presence => true, :numericality => { :greater_than_or_equal_to => 0 }
  validates :installment_amount, :numericality => { :greater_than_or_equal_to => 0 }, if: Proc.new{ |tom| tom.is_payment_expected }
  validates :installment_type, :presence => true
  validates :initial_club_cash_amount, :numericality => { :greater_than_or_equal_to => 0 }
  validates :club_cash_installment_amount, :numericality => { :greater_than_or_equal_to => 0 }, if: Proc.new{ |tom| tom.is_payment_expected }
  # validates :initial_fee, :numericality => { :greater_than_or_equal_to => 0 }
  # validates :trial_period_amount, :numericality => { :greater_than_or_equal_to => 0 }
  validates :is_payment_expected, :inclusion => { :in => [true, false] } 
  validates :subscription_limits, :numericality => { :greater_than_or_equal_to => 0 }
  validates :if_cannot_bill, :presence => true
  validates :downgrade_tom_id, :presence => true, if: Proc.new { |tom| tom.downgradable? }
  validates :upgrade_tom_period, :presence => true, :numericality => { :greater_than_or_equal_to => 1 }, if: Proc.new{ |tom| tom.upgradable? }

  validate :validate_payment_gateway_configuration

  before_destroy :can_update_or_delete
  before_update :can_update_or_delete

  ###########################################
  
  def payment_gateway_configuration
    club.payment_gateway_configurations.first
  end
  
  def downgradable?
    self.if_cannot_bill == 'downgrade_tom'
  end

  def suspendable?
    self.if_cannot_bill == 'suspend'
  end

  def upgradable?
    !self.upgrade_tom_id.nil?
  end

  def cancelable?
    self.if_cannot_bill == 'cancel'
  end

  def self.datatable_columns
    ['id', 'name', 'api_role', 'created_at', 'agent_id']
  end

  def can_update_or_delete
    not self.memberships.first and not self.prospects.first
  end

  private
    def validate_payment_gateway_configuration
      errors.add :base, I18n.t("error_messages.club_payment_gateway_configuration_not_created", :link => Rails.application.routes.url_helpers.new_payment_gateway_configuration_path(partner_prefix: self.club.partner.prefix, club_prefix: self.club.name)).html_safe unless self.payment_gateway_configuration
    end

    def setup_default_email_templates
      unless Rails.env.production?
        EmailTemplate::TEMPLATE_TYPES.each do |type|
          if type!=:rejection or (type==:rejection and self.needs_enrollment_approval)
            et = EmailTemplate.new 
            et.name = "Test #{type}"
            et.client = :action_mailer
            et.template_type = type
            et.days = 7 if et.is_prebill?
            et.terms_of_membership_id = self.id
            et.save
          end
        end
      end
    end
    
end
