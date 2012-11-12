class TermsOfMembership < ActiveRecord::Base
  attr_accessible :grace_period, :mode, :needs_enrollment_approval, :provisional_days, 
    :installment_amount, :description, :installment_type, :club, :name, :club_cash_amount

  belongs_to :club
  has_many :transactions
  has_many :memberships
  has_many :prospects

  acts_as_paranoid

  validates :name, :presence => true
  validates :grace_period, :presence => true
  validates :mode, :presence => true
  #validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :provisional_days, :presence => true
  validates :installment_amount, :presence => true
  validates :installment_type, :presence => true
  validates :club_cash_amount, :numericality => { :greater_than_or_equal_to => 0 }
  validate :validate_payment_gateway_configuration

  ###########################################
  # Installment types:
  def monthly?
    installment_type == "1.month"
  end

  def yearly?
    installment_type == "1.year"
  end

  def lifetime?
    installment_type == "lifetime"
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

  private

    def validate_payment_gateway_configuration
      errors.add :base, :club_payment_gateway_configuration unless self.payment_gateway_configuration
    end

end
