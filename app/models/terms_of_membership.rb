class TermsOfMembership < ActiveRecord::Base
  attr_accessible :grace_period, :mode, :needs_enrollment_approval, :trial_days, 
    :installment_amount, :description, :installment_type

  belongs_to :club
  has_many :members

  acts_as_paranoid

  validates :grace_period, :presence => true
  validates :mode, :presence => true
  validates :needs_enrollment_approval, :presence => true
  validates :club, :presence => true
  validates :trial_days, :presence => true
  validates :installment_amount, :presence => true
  validates :installment_type, :presence => true

  MODES = ['development', 'production']
  
  def production?
    self.mode == 'production'
  end
  def development?
    self.mode == 'development'
  end    
end
