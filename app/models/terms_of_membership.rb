class TermsOfMembership < ActiveRecord::Base
  attr_accessible :bill_type, :enrollment_price, :grace_period, 
    :max_reactivations, :mode, :needs_enrollment_approval, :trial_days, 
    :year_price, :description

  belongs_to :club
  has_many :members

  acts_as_paranoid

  validates :bill_type, :presence => true
  validates :enrollment_price, :presence => true
  validates :grace_period, :presence => true
  validates :max_reactivations, :presence => true
  validates :mode, :presence => true
  validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :trial_days, :presence => true
  validates :year_price, :presence => true

  MODES = ['development', 'production']
  # BILL_TYPES => if we dont want to bill , we can set enrollment_price and year_price = 0.0
  BILL_TYPES = ['monthly', 'yearly', 'lifetime'] 

  def production?
    self.mode == 'production'
  end
  def development?
    self.mode == 'development'
  end    
end
