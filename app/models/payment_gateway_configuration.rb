class PaymentGatewayConfiguration < ActiveRecord::Base
  attr_accessible :login, :merchant_key, :password, :mode, :gateway, :club
  
  belongs_to :club
  has_many :transactions

  acts_as_paranoid

  validates :login, :presence => true
  validates :merchant_key, :presence => true
  validates :password, :presence => true
  validates :mode, :presence => true
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
