class PaymentGatewayConfiguration < ActiveRecord::Base
  attr_accessible :login, :merchant_key, :password, :gateway, :report_group, :aus_login, :aus_password

  belongs_to :club
  has_many :transactions

  acts_as_paranoid
  validates_as_paranoid

  validates :login, :presence => true
  validates :merchant_key, :presence => true
  validates :password, :presence => true
  validates :gateway, :presence => true
  validates :club, :presence => true

  def mes?
    self.gateway == 'mes'
  end
  def litle?
    self.gateway == 'litle'
  end
  def authorize_net?
    self.gateway == "authorize_net"
  end

end
