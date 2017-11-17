class PaymentGatewayConfiguration < ActiveRecord::Base
  belongs_to :club
  has_many :transactions

  acts_as_paranoid

  serialize :additional_attributes, JSON

  validates :login, presence: true
  validates :merchant_key, presence: true, if: Proc.new { |pgc| pgc.litle? }
  validates :password, presence: true
  validates :gateway, presence: true, 
                      uniqueness: { scope: [ :club_id ], message: "already created. There is a payment gateway already configured for this gateway." }
  
  validates :club, presence: true

  before_create :only_one_is_allowed
  
  scope :where_active, -> (gateway) { joins(:club).where(clubs: {billing_enable: true}).where(gateway: gateway) }
  
  def trust_commerce?
    gateway == "trust_commerce"
  end

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

  def stripe?
    self.gateway == "stripe"
  end
  
  def payeezy?
    self.gateway == 'payeezy'
  end

  def only_one_is_allowed
    if club and self.club.payment_gateway_configurations.count > 0 
      errors.add :base, error: "There is already one payment gateway configuration active on that club #{club_id}"
      false
    end
  end

end
