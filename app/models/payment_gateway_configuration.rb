class PaymentGatewayConfiguration < ActiveRecord::Base
  attr_accessible :login, :merchant_key, :password, :mode, :gateway, :report_group
  
  belongs_to :club
  has_many :transactions

  acts_as_paranoid
  validates_as_paranoid

  validates :login, :presence => true
  validates :merchant_key, :presence => true
  validates :password, :presence => true
  validates :mode, :presence => true
  validates :gateway, :presence => true
  validates :club, :presence => true
  validates_uniqueness_of_without_deleted :mode, :scope => :club_id

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

  def self.process_mes_chargebacks(mode)
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', mode).each do |gateway|
      MesAccountUpdater.process_chargebacks gateway
    end
  end

  def self.account_updater_process_answers(mode)
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', mode).each do |gateway|
      MesAccountUpdater.account_updater_process_answers gateway
    end
  end
  
  def self.account_updater_send_file_to_process(mode)
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', mode).each do |gateway|
      MesAccountUpdater.account_updater_send_file_to_process gateway
    end
  end

end
