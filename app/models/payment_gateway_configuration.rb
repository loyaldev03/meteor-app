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

  def process_mes_chargebacks
    conn = Faraday.new(:url => Settings.mes_report_service.url, :ssl => {:verify => false})
    initial_date, end_date = (Date.today - 1.days).strftime('%m/%d/%Y'), (Date.today - 1.days).strftime('%m/%d/%Y')
    merchant_id = self.login[0..11]
    result = conn.get Settings.mes_report_service.path, { 
      :userId => Settings.mes_report_service.user, 
      :userPass => Settings.mes_report_service.password, 
      :reportDateBegin => initial_date, 
      :reportDateEnd => end_date, 
      :nodeId => merchant_id, 
      :reportType => 1, 
      :includeTridentTranId => true, 
      :includePurchaseId => true, 
      :includeClientRefNum => true, 
      :dsReportId => 5
    }
    process_mes_chargebacks_result(result.body) if result.success?
  end

  def self.process_mes_chargebacks(mode)
    PaymentGatewayConfiguration.find_all_by_gateway_and_mode('mes', mode).each do |gateway|
      gateway.process_mes_chargebacks
    end
  end

  private
    def process_mes_chargebacks_result(body)
      body.split("\n").each do |line|
        columns = line.split(',')
        next if columns[0].include?('Merchant Id')
        columns.each { |x| x.gsub!('"', '') }
        args = { :control_number => columns[2], :incomming_date => columns[3],
          :reference_number => columns[5], :transaction_date => columns[6], :transaction_amount => columns[7],
          :trident_transaction_id => columns[8], :purchase_transaction_id => columns[9],
          :client_reference_number => columns[10], :auth_code => columns[11],
          :adjudication_date => columns[12], :adjudication_number => columns[13],
          :reason => columns[14], :first_time => columns[15],
          :reason_code => columns[16], :cb_ref_number => columns[17]
        }
        begin
          transaction_chargebacked = Transaction.find_by_payment_gateway_configuration_id_and_response_transaction_id self.id, args[:trident_transaction_id]
          member = Member.find_by_visible_id_and_club_id(args[:client_reference_number], self.club_id)
          if transaction_chargebacked.member_id == member.id
            member.chargeback! transaction_chargebacked, args
            member.save
          else
            raise "Chargeback ##{args[:control_number]} could not be processed. member and transaction_chargebacked are different! #{line}"
          end
        rescue Exception => e
          Airbrake.notify(:error_class => "MES::chargeback_report", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}")
          Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        end
      end
    end      
end
