class Transaction < ActiveRecord::Base
  belongs_to :user
  belongs_to :membership
  belongs_to :payment_gateway_configuration
  belongs_to :decline_strategy
  belongs_to :credit_card
  # This value will be not nil only if we are billing
  belongs_to :terms_of_membership
  has_many :operations, as: :resource

  serialize :response, JSON

  attr_accessor :refund_response_transaction_id, :stripe_customer_id

  before_save :validate_adjudication_date, :if => lambda {|record| [Settings.operation_types.chargeback, Settings.operation_types.chargeback_rebutted].include? record.operation_type}

  scope :refunds, lambda { where('transaction_type IN (?, ?)', 'credit', 'refund') }

  ONE_TIME_BILLINGS = ["one-time", "donation"]
  STORE_ERROR_NOT_REPORTABLE = {
    'mes' => %w{117},
    'trust_commerce' => %w{decline call carderror rejected baddata error},
    'stripe' => %w{card_declined incorrect_number},
    'litle' => %{}
  }

  def full_label
    transaction_type ?
    I18n.t('activerecord.attributes.transaction.transaction_types.'+transaction_type) +
      ( response_result.nil? ? '' : ' : ' + response_result) : ''
  end

  def self.datatable_columns
    ['created_at']
  end

  def user=(user)
    self.user_id = user.id
    self.first_name = user.first_name
    self.last_name = user.last_name
    self.phone_number = user.full_phone_number
    self.email = user.email
    self.address = user.address
    self.city = user.city
    self.state = user.state
    self.country = user.country
    self.zip = user.zip
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
    self.gateway = pgc.gateway
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
  end

  def prepare(user, credit_card, amount, payment_gateway_configuration, terms_of_membership_id = nil, membership = nil, operation_type_to_set = nil)
    self.user = user
    self.stripe_customer_id = user.stripe_id
    self.credit_card = credit_card
    self.amount = amount
    self.payment_gateway_configuration = payment_gateway_configuration
    self.membership_id = membership.nil? ? user.current_membership_id : membership.id
    self.terms_of_membership_id = terms_of_membership_id || user.terms_of_membership.id 
    self.operation_type = operation_type_to_set
    self.club_id = user.club_id
    self.save
    @options = {
      order_id: invoice_number,
      billing_address: {
        name: "#{first_name} #{last_name}",
        address1: address[0..34], # Litle has this restriction of characters.
        city: city,
        state: state,
        zip: zip.to_s.gsub(/[a-zA-Z-]/, ''),
        phone: phone_number
      },
      expiration_date: "%02d%s" % [ self.expire_month.to_i, self.expire_year.to_s.last(2) ]
    }
  end

  def prepare_no_recurrent(user, credit_card, amount, payment_gateway_configuration, terms_of_membership_id = nil, membership = nil, type)
    operation_type = type=="one-time" ? Settings.operation_types.no_recurrent_billing : Settings.operation_types.no_reccurent_billing_donation
    prepare(user, credit_card, amount, payment_gateway_configuration, terms_of_membership_id, membership, operation_type)
  end

  def prepare_for_manual(user, amount, operation_type_to_set)
    self.terms_of_membership_id = user.terms_of_membership.id
    self.user = user
    self.amount = amount
    self.membership_id = user.current_membership_id
    self.operation_type = operation_type_to_set
    self.gateway = :manual
    self.save
  end

  def can_be_chargeback?
    [ 'sale' ].include?(transaction_type) and trust_commerce? and amount_available_to_refund > 0.0 and self.success? and Transaction.where("user_id = ? AND transaction_type = ? AND response like ?", self.user_id, "chargeback", "%#{self.id}%").empty?
  end

  def can_be_refunded?    
    [ 'sale' ].include?(transaction_type) and amount_available_to_refund > 0.0 and !user.blacklisted? and self.success? and has_same_pgc_as_current? 
  end

  def has_same_pgc_as_current?
    gateway == user.club.payment_gateway_configurations.first.gateway
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
      when "balance"
        balance
      # when "void"
      #   void
      #when "authorization_capture"
      #  authorization_capture
      else
        { message: "Operation -#{transaction_type}- not supported", code: Settings.error_codes.not_supported }
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

  def trust_commerce?
    gateway == "trust_commerce"
  end

  def stripe?
    gateway == "stripe"
  end

  def one_time_type?
    operation_type == Settings.operation_types.no_recurrent_billing
  end

  # answer credit card token
  def self.store!(am_credit_card, pgc, user=nil)
    if pgc.mes?
      MerchantESolutionsTransaction.store!(am_credit_card, pgc)
    elsif pgc.litle?
      LitleTransaction.store!(am_credit_card, pgc)
    elsif pgc.authorize_net?
      AuthorizeNetTransaction.store!(am_credit_card, pgc)
    elsif pgc.first_data?
      FirstDataTransaction.store!(am_credit_card, pgc)
    elsif pgc.trust_commerce?
      TrustCommerceTransaction.store!(am_credit_card, pgc)
    elsif pgc.stripe?
      StripeTransaction.store!(am_credit_card, pgc, user)
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
    when 'trust_commerce'
      TrustCommerceTransaction.new
    when 'stripe'
      StripeTransaction.new
    else
      raise "No payment gateway configuration set for gateway \"#{gateway}\""
    end
  end

  def self.refund(amount, sale_transaction_id, agent=nil, update_refunded_amount = true, operation_type_to_set = Settings.operation_types.credit)
    Transaction.transaction do
      sale_transaction = Transaction.lock(true).find(sale_transaction_id)
      if not sale_transaction.has_same_pgc_as_current?
        { code: Settings.error_codes.transaction_gateway_differs_from_current, message: I18n.t("error_messages.transaction_gateway_differs_from_current") }
      else
        amount = amount.to_f
        if amount <= 0.0
          return { message: I18n.t('error_messages.credit_amount_invalid'), code: Settings.error_codes.credit_amount_invalid }
        elsif sale_transaction.amount_available_to_refund.to_f < amount
          return { message: I18n.t('error_messages.refund_invalid'), code: Settings.error_codes.refund_invalid }
        end
        trans = Transaction.obtain_transaction_by_gateway!(sale_transaction.gateway)
        trans.prepare(sale_transaction.user, sale_transaction.credit_card, -amount, sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, sale_transaction.membership, operation_type_to_set)
        trans.fill_transaction_type_for_credit(sale_transaction)
        answer = trans.process
        if trans.success?
          sale_transaction.refunded_amount = sale_transaction.refunded_amount + amount if update_refunded_amount
          sale_transaction.save
          Auditory.audit(agent, trans, "Refund success $#{amount} on transaction #{sale_transaction.id}", sale_transaction.user, Settings.operation_types.credit)
          Communication.deliver!(:refund, sale_transaction.user)
          sale_transaction.user.update_attribute :need_sync_to_marketing_client, true
        else
          Auditory.audit(agent, trans, "Refund $#{amount} error: #{answer[:message]}", sale_transaction.user, Settings.operation_types.credit_error)
          trans.update_attribute :operation_type, Settings.operation_types.credit_error
        end
        answer
      end
    end
  end

  def self.generate_balance_transaction(agent, user, amount, membership, transaction_to_refund = nil)
    trans = Transaction.obtain_transaction_by_gateway!(membership.terms_of_membership.payment_gateway_configuration.gateway)
    trans.transaction_type = "balance"
    trans.prepare(user, user.active_credit_card, amount, membership.terms_of_membership.payment_gateway_configuration, membership.terms_of_membership.id, membership, Settings.operation_types.membership_balance_transfer)
    trans.process
    transaction_to_refund.update_attribute :refunded_amount, amount.abs if transaction_to_refund
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
      expired_codes = ['522','605']
    elsif self.trust_commerce?
      expired_codes = ['expiredcard']
    end
    expired_codes.include? self.response_code
  end

  private

    def amount_to_send
      (amount.to_f * 100).round.abs
    end

    def credit
      if payment_gateway_configuration.nil?
        save_custom_response({ message: "Payment gateway not found.", code: Settings.error_codes.not_found })
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ code: Settings.error_codes.credit_card_blank_without_grace, message: "Credit card is blank we wont bill" })
      else
        load_gateway
        credit_response=@gateway.credit(amount_to_send, credit_card_token, @options)
        save_response(credit_response)
      end
    rescue Timeout::Error
      save_custom_response({ code: Settings.error_codes.payment_gateway_time_out, message: I18n.t('error_messages.payment_gateway_time_out') })
    rescue Exception => e
      response = save_custom_response({ code: Settings.error_codes.payment_gateway_error, message: I18n.t('error_messages.airbrake_error_message') })
      Auditory.report_issue("Transaction::Credit", e, {user: self.user.id, transaction: "ID: #{self.id}, amount: #{self.amount}, response: #{self.response}"})
      response
    end

    def refund
      if payment_gateway_configuration.nil?
        save_custom_response({ message: "Payment gateway not found.", code: Settings.error_codes.not_found })
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ code: Settings.error_codes.credit_card_blank_without_grace, message: "Credit card is blank we wont bill" })
      else
        load_gateway
        refund_response=@gateway.refund(amount_to_send, refund_response_transaction_id, @options)
        save_response(refund_response)
      end
    rescue Timeout::Error
      save_custom_response({ code: Settings.error_codes.payment_gateway_time_out, message: I18n.t('error_messages.payment_gateway_time_out') })
    rescue Exception => e
      response = save_custom_response({ code: Settings.error_codes.payment_gateway_error, message: I18n.t('error_messages.airbrake_error_message') })
      Auditory.report_issue("Transaction::Refund", e, {user: self.user.id, transaction: "ID: #{self.id}, amount: #{self.amount}, response: #{self.response}"})
      response
    end

    # Process only sale operations
    def sale
      if payment_gateway_configuration.nil?
        save_custom_response({ message: "Payment gateway not found.", code: Settings.error_codes.not_found })
      elsif amount.to_f == 0.0
        save_custom_response({ message: "Transaction success. Amount $0.0", code: Settings.error_codes.success }, true)
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ code: Settings.error_codes.credit_card_blank_without_grace, message: "Credit card is blank we wont bill" })
      else
        load_gateway
        purchase_response = @gateway.purchase(amount_to_send, credit_card_token, @options)
        save_response(purchase_response)
      end
    end

    def sale_manual
      purchase_response = { message: "Manual transaction success. Amount $#{self.amount}", code: Settings.error_codes.success }
      save_custom_response(purchase_response, true)
    end

    def balance
      save_custom_response({ message: "Balance transaction.", code: Settings.error_codes.success }, true)
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
        { message: I18n.t('error_messages.duplicate_transaction', response: response.params[:response]), code: Settings.error_codes.duplicate_transaction }
      elsif answer.success?
        unless self.credit_card.nil?
          self.credit_card.accepted_on_billing
        end
        { message: answer.message, code: Settings.error_codes.success }
      else
        { message: "Error: " + answer.message.to_s, code: self.response_code }
      end
    end

    def validate_adjudication_date
      if HashWithIndifferentAccess.new(self.response)[:adjudication_date].blank?
        errors[:adjudication_date] << "cannot be blank"
        return false
      end
    end
end
