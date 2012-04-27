class TermsOfMembership < ActiveRecord::Base
  attr_accessible :grace_period, :mode, :needs_enrollment_approval, :trial_days, 
    :installment_amount, :description, :installment_type, :club, :name

  belongs_to :club
  has_many :transactions
  has_many :members

  acts_as_paranoid

  validates :name, :presence => true
  validates :grace_period, :presence => true
  validates :mode, :presence => true
  #validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :trial_days, :presence => true
  validates :installment_amount, :presence => true
  validates :installment_type, :presence => true


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

end
