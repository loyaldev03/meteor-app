class Transaction < ActiveRecord::Base
  belongs_to :member
  belongs_to :membership
  belongs_to :payment_gateway_configuration
  belongs_to :decline_strategy
  belongs_to :credit_card
  # This value will be not nil only if we are billing 
  belongs_to :terms_of_membership 
  has_many :operations, :as => :resource

  serialize :response, JSON

  attr_accessor :refund_response_transaction_id

  scope :refunds, lambda { where('transaction_type IN (?, ?)', 'credit', 'refund') }

  ONE_TIME_BILLINGS = ["one-time", "donation"]

  def full_label
    transaction_type ?
    I18n.t('activerecord.attributes.transaction.transaction_types.'+transaction_type) + 
      ( response_result.nil? ? '' : ' : ' + response_result) : ''
  end

  def self.datatable_columns
    ['created_at']
  end

  def member=(member)
    self.member_id = member.id
    self.first_name = member.first_name
    self.last_name = member.last_name
    self.phone_number = member.full_phone_number
    self.email = member.email
    self.address = member.address
    self.city = member.city
    self.state = member.state
    self.country = member.country
    self.zip = member.zip
  end

  def credit_card=(credit_card)
    return if credit_card.nil?
    self.credit_card_id = credit_card.id
    self.token = credit_card.token
    self.cc_type = credit_card.cc_type
    self.last_digits = credit_card.last_digits
    self.expire_month = credit_card.expire_month
    self.expire_year = credit_card.expire_year
  end

  def payment_gateway_configuration=(pgc)
    self.payment_gateway_configuration_id = pgc.id
    self.report_group = pgc.report_group
    self.merchant_key = pgc.merchant_key
    self.login = pgc.login
    self.password = pgc.password
    self.descriptor_name = pgc.descriptor_name
    self.descriptor_phone = pgc.descriptor_phone
    self.order_mark = pgc.order_mark
    self.gateway = pgc.gateway
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
  end

  def prepare(member, credit_card, amount, payment_gateway_configuration, terms_of_membership_id = nil, membership = nil, operation_type_to_set = nil)
    self.member = member
    self.credit_card = credit_card
    self.amount = amount
    self.payment_gateway_configuration = payment_gateway_configuration
    self.membership_id = membership.nil? ? member.current_membership_id : membership.id 
    self.terms_of_membership_id = terms_of_membership_id || member.terms_of_membership.id
    self.operation_type = operation_type_to_set
    self.save
    @options = {
      :order_id => invoice_number,
      :billing_address => {
        :name     => "#{first_name} #{last_name}",
        :address1 => address[0..34], # Litle has this restriction of characters.
        :city     => city,
        :state    => state,
        :zip      => zip.to_s.gsub(/[a-zA-Z-]/, ''),
        :phone    => phone_number
      },
      :expiration_date => "%02d%s" % [ self.expire_month.to_i, self.expire_year.to_s.last(2) ]
    }    
  end

  def prepare_no_recurrent(member, credit_card, amount, payment_gateway_configuration, terms_of_membership_id = nil, membership = nil, type)
    operation_type = type=="one-time" ? Settings.operation_types.no_recurrent_billing : Settings.operation_types.no_reccurent_billing_donation
    prepare(member, credit_card, amount, payment_gateway_configuration, terms_of_membership_id, membership, operation_type)
  end

  def prepare_for_manual(member, amount, operation_type_to_set)
    self.terms_of_membership_id = member.terms_of_membership.id
    self.member = member
    self.amount = amount
    self.membership_id = member.current_membership_id 
    self.operation_type = operation_type_to_set
    self.gateway = :manual
    self.save    
  end

  def can_be_refunded?
    [ 'sale' ].include?(transaction_type) and amount_available_to_refund > 0.0 and !member.blacklisted? and self.success? and has_same_pgc_as_current?
  end

  def has_same_pgc_as_current?
    gateway == member.club.payment_gateway_configurations.first.gateway
  end

  def process
    case transaction_type
      when "sale"
        sale
      when "sale_manual_cash", "sale_manual_check"
        sale_manual
      #when "authorization"
      #  authorization
      #when "capture"
      #  capture
      when "credit"
        credit
      when "refund"
        refund
      # when "void"
      #   void
      #when "authorization_capture"
      #  authorization_capture
      else
        { :message=>"Operation -#{transaction_type}- not supported", :code=> Settings.error_codes.not_supported }
    end
  end  

  def mes?
    gateway == "mes"
  end

  def litle?
    gateway == "litle"
  end

  def authorize_net?
    gateway == "authorize_net"
  end

  def first_data?
    gateway == "first_data"
  end

  def one_time_type?
    operation_type == Settings.operation_types.no_recurrent_billing
  end

  # answer credit card token
  def self.store!(am_credit_card, pgc)
    if pgc.mes?
      MerchantESolutionsTransaction.store!(am_credit_card, pgc)
    elsif pgc.litle?
      LitleTransaction.store!(am_credit_card, pgc)
    elsif pgc.authorize_net?
      AuthorizeNetTransaction.store!(am_credit_card, pgc)
    elsif pgc.first_data?
      FirstDataTransaction.store!(am_credit_card, pgc)
    else
      raise "No payment gateway configuration set for gateway \"#{pgc.gateway}\""
    end
  end

  def self.obtain_transaction_by_gateway!(gateway)
    case gateway
    when 'mes'
      MerchantESolutionsTransaction.new
    when 'litle'
      LitleTransaction.new
    when 'authorize_net'
      AuthorizeNetTransaction.new
    when 'first_data'
      FirstDataTransaction.new
    else
      raise "No payment gateway configuration set for gateway \"#{gateway}\""
    end
  end


  def self.refund(amount, sale_transaction_id, agent=nil)
    # Lock transaction, so no one can use this record while we refund this member.
    sale_transaction = Transaction.find sale_transaction_id, :lock => true
    if not sale_transaction.has_same_pgc_as_current?
      { :code => Settings.error_codes.transaction_gateway_differs_from_current, :message => I18n.t("error_messages.transaction_gateway_differs_from_current") }
    else 
      Transaction.transaction do 
        amount = amount.to_f
        if amount <= 0.0
          return { :message => I18n.t('error_messages.credit_amount_invalid'), :code => Settings.error_codes.credit_amount_invalid }
        elsif sale_transaction.amount_available_to_refund.to_f < amount
          return { :message => I18n.t('error_messages.refund_invalid'), :code => Settings.error_codes.refund_invalid }
        end
        trans = Transaction.obtain_transaction_by_gateway!(sale_transaction.gateway)
        trans.prepare(sale_transaction.member, sale_transaction.credit_card, -amount, sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, sale_transaction.membership, Settings.operation_types.credit)
        trans.fill_transaction_type_for_credit(sale_transaction)
        answer = trans.process
        if trans.success?
          sale_transaction.refunded_amount = sale_transaction.refunded_amount + amount
          sale_transaction.save
          Auditory.audit(agent, trans, "Refund success $#{amount} on transaction #{sale_transaction.id}", sale_transaction.member, Settings.operation_types.credit)
          Communication.deliver!(:refund, sale_transaction.member)
          sale_transaction.member.update_attribute :need_exact_target_sync, true
        else
          Auditory.audit(agent, trans, "Refund $#{amount} error: #{answer[:message]}", sale_transaction.member, Settings.operation_types.credit_error)
          trans.update_attribute :operation_type, Settings.operation_types.credit_error
        end
        answer
      end
    end
  end

  def amount_available_to_refund
    amount - refunded_amount
  end

  def is_response_code_cc_expired?
    expired_codes = []
    if self.mes?
      expired_codes = ['054']
    elsif self.authorize_net?
      expired_codes = ['8','316']
    elsif self.litle?
      expired_codes = ['305']
    elsif self.first_data?
      expire_codes = ['522']
    end
    expired_codes.include? self.response_code 
  end

  private

    def amount_to_send
      (amount.to_f * 100).round.abs
    end

    def credit
      if payment_gateway_configuration.nil?
        save_custom_response({ :message => "Payment gateway not found.", :code => Settings.error_codes.not_found })
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ :code => Settings.error_codes.credit_card_blank_without_grace, :message => "Credit card is blank we wont bill" })
      else
        load_gateway
        credit_response=@gateway.credit(amount_to_send, credit_card_token, @options)
        save_response(credit_response)
      end
    rescue Timeout::Error
      save_custom_response({ :code => Settings.error_codes.payment_gateway_time_out, :message => I18n.t('error_messages.payment_gateway_time_out') })
    rescue Exception => e
      response = save_custom_response({ :code => Settings.error_codes.payment_gateway_error, :message => I18n.t('error_messages.airbrake_error_message') })
      Auditory.report_issue("Transaction::Credit", e, {:member => self.member.inspect, :transaction => self.inspect })
      response
    end

    def refund
      if payment_gateway_configuration.nil?
        save_custom_response({ :message => "Payment gateway not found.", :code => Settings.error_codes.not_found })
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ :code => Settings.error_codes.credit_card_blank_without_grace, :message => "Credit card is blank we wont bill" })
      else
        load_gateway        
        refund_response=@gateway.refund(amount_to_send, refund_response_transaction_id, @options)
        save_response(refund_response)
      end
    rescue Timeout::Error
      save_custom_response({ :code => Settings.error_codes.payment_gateway_time_out, :message => I18n.t('error_messages.payment_gateway_time_out') })
    rescue Exception => e
      response = save_custom_response({ :code => Settings.error_codes.payment_gateway_error, :message => I18n.t('error_messages.airbrake_error_message') })
      Auditory.report_issue("Transaction::Refund", e, {:member => self.member.inspect, :transaction => self.inspect })
      response
    end    

    # Process only sale operations
    def sale
      if payment_gateway_configuration.nil?
        save_custom_response({ :message => "Payment gateway not found.", :code => Settings.error_codes.not_found })
      elsif amount.to_f == 0.0
        save_custom_response({ :message => "Transaction success. Amount $0.0", :code => Settings.error_codes.success }, true)
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ :code => Settings.error_codes.credit_card_blank_without_grace, :message => "Credit card is blank we wont bill" })
      else
        load_gateway
        purchase_response = @gateway.purchase(amount_to_send, credit_card_token, @options)
        save_response(purchase_response)
      end
    end

    def sale_manual
      purchase_response = { :message => "Manual transaction success. Amount $#{self.amount}", :code => Settings.error_codes.success }
      save_custom_response(purchase_response, true)
    end

    def save_custom_response(answer, trans_success=false)
      self.success=trans_success
      self.response=answer
      self.response_code=answer[:code]
      self.response_result=answer[:message]
      self.save
      answer
    end

    def save_response(answer)
      if answer.params and answer.params[:duplicate]=="true"
        # we keep this if, just because it was on Litle version (compatibility).
        # MeS seems to not send this param
        { :message => I18n.t('error_messages.duplicate_transaction', :response => response.params[:response]), :code => Settings.error_codes.duplicate_transaction }
      elsif answer.success?
        unless self.credit_card.nil?
          self.credit_card.accepted_on_billing
        end
        { :message => answer.message, :code=> Settings.error_codes.success }
      else
        { :message=>"Error: " + answer.message, :code=>self.response_code }
      end      
    end  
end
