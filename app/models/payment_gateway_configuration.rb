class PaymentGatewayConfiguration < ActiveRecord::Base
  attr_accessible :login, :merchant_key, :password, :gateway, :report_group, :aus_login, :aus_password

  belongs_to :club
  has_many :transactions

  acts_as_paranoid
  validates_as_paranoid

  validates :login, :presence => true
  validates :merchant_key, :presence => true
  validates :password, :presence => true
  validates :gateway, :presence => true, uniqueness_without_deleted: { scope: [ :club_id ], :message => "already created. There is a payment gateway already configured for this gateway." } 
  validates :club, :presence => true

  before_create :only_one_is_allowed
  
  def mes?
    self.gateway == 'mes'
  end

  def litle?
    self.gateway == 'litle'
  end

  def authorize_net?
    self.gateway == "authorize_net"
  end

  def first_data?
    self.gateway == "first_data"
  end

  def only_one_is_allowed
    if club and self.club.payment_gateway_configurations.count > 0 
      errors.add :base, :error => "There is already one payment gateway configuration active on that club #{club_id}"
      false
    end
  end

end
