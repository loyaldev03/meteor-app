class PaymentGatewayConfiguration < ActiveRecord::Base
  attr_accessible :login, :merchant_key, :password, :mode, :gateway, :report_group
  
  belongs_to :club
  has_many :transactions

  acts_as_paranoid

  validates :login, :presence => true
  validates :merchant_key, :presence => true
  validates :password, :presence => true
  validates :mode, :presence => true, :uniqueness => { :message => "There is already one payment gateway configuration with this mode.", 
                                                       :scope => :club_id }
  validates :gateway, :presence => true
  validates :club, :presence => true

  def mes?
    self.gateway == 'mes'
  end
  def litle?
    self.gateway == 'litle'
  end
  def production?
    self.mode == 'production'
  end
  def development?
    self.mode == 'development'
  end
end
