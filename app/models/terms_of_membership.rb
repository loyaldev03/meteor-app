class TermsOfMembership < ActiveRecord::Base
  attr_accessible :mode, :needs_enrollment_approval, :provisional_days, 
    :installment_amount, :description, :installment_type, :club, :name, :club_cash_amount, :agent_id

  belongs_to :club
  has_many :transactions
  has_many :memberships
  has_many :prospects
  has_many :email_templates
  belongs_to :downgrade_tom, :class_name => 'TermsOfMembership', :foreign_key => 'downgrade_tom_id'
  belongs_to :agent

  acts_as_paranoid

  after_create :setup_default_email_templates

  validates :name, :presence => true
  validates :mode, :presence => true
  #validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :provisional_days, :presence => true
  validates :installment_amount, :presence => true
  validates :installment_type, :presence => true
  validates :quota, :presence => true
  validates :club_cash_amount, :numericality => { :greater_than_or_equal_to => 0 }
  validate :validate_payment_gateway_configuration

  before_destroy :verify_that_there_are_not_memberships_and_prospects
  before_update :verify_that_there_are_not_memberships_and_prospects

  ###########################################
  # Installment types:
  def monthly?
    installment_type == "1.month"
  end

  def yearly?
    installment_type == "1.year"
  end

  def lifetime?
    installment_type == "1000.years"
  end
  #################################
  
  def production?
    self.mode == 'production'
  end

  def development?
    self.mode == 'development'
  end

  def payment_gateway_configuration
    club.payment_gateway_configurations.find_by_mode(mode)
  end
  
  def downgradable?
    self.downgrade_tom_id.to_i > 0
  end

  def self.datatable_columns
    ['id', 'name', 'api_role', 'created_at', 'agent_id']
  end

  private

    def validate_payment_gateway_configuration
      errors.add :base, :club_payment_gateway_configuration unless self.payment_gateway_configuration
    end

    def setup_default_email_templates
      if development?
        EmailTemplate::TEMPLATE_TYPES.each do |type|
          if type!=:rejection or (type==:rejection and self.needs_enrollment_approval)
            et = EmailTemplate.new 
            et.name = "Test #{type}"
            et.client = :action_mailer
            et.template_type = type
            et.terms_of_membership_id = self.id
            et.save
          end
        end
      end
    end

    def verify_that_there_are_not_memberships_and_prospects
      self.memberships.count == 0 && self.prospects.count == 0
    end

end
