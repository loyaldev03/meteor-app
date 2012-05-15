class Transaction < ActiveRecord::Base
  include Extensions::UUID

  belongs_to :member
  belongs_to :payment_gateway_configuration
  belongs_to :decline_strategy
  belongs_to :credit_card
  # This value will be not nil only if we are billing 
  belongs_to :terms_of_membership 

  attr_encrypted :number, :key => Settings.cc_encryption_key, :encode => true, :algorithm => 'bf'

  def to_label
    I18n.t('activerecord.attributes.transaction.transaction_types.'+transaction_type) + ': ' + response_result[0..50]
  end

  def member=(member)
    self.member_id = member.id
    # MeS supports only 17 characters on order_id
    self.invoice_number = member.visible_id
    self.first_name = member.first_name
    self.last_name = member.last_name
    self.phone_number = member.phone_number
    self.email = member.email
    self.address = member.address
    self.city = member.city
    self.state = member.state
    self.zip = member.zip
  end

  def credit_card=(credit_card)
    self.credit_card_id = credit_card.id
    self.encrypted_number = credit_card.encrypted_number
    self.expire_month = credit_card.expire_month
    self.expire_year = credit_card.expire_year
  end

  def payment_gateway_configuration=(pgc)
    self.payment_gateway_configuration_id = pgc.id
    self.report_group = pgc.report_group
    self.merchant_key = pgc.merchant_key
    self.login = pgc.login
    self.password = pgc.password
    self.mode = pgc.mode
    self.descriptor_name = pgc.descriptor_name
    self.descriptor_phone = pgc.descriptor_phone
    self.order_mark = pgc.order_mark
    self.gateway = pgc.gateway
  end

  def prepare(member, credit_card, amount, payment_gateway_configuration)
    self.member = member
    self.credit_card = credit_card
    self.amount = amount
    self.payment_gateway_configuration = payment_gateway_configuration
    self.save
  end

  def success?
    response_code == "000"
  end

  def can_be_refunded?
    [ 'sale', 'capture' ].include?(transaction_type) and amount_available_to_refund > 0.0
  end


  def process
    case transaction_type
      when "sale"
        sale
      #when "authorization"
      #  authorization
      #when "capture"
      #  capture
      when "credit"
        credit
      when "refund"
        refund
      when "void"
        void
      #when "authorization_capture"
      #  authorization_capture
      else
        { :message=>"Operation -#{transaction_type}- not supported",:code=> '902' }
    end
  end  

  def production?
    mode == "production"
  end

  def mes?
    gateway == "mes"
  end

  # we will use ActiveMerchant::Billing::CreditCardMethods::CARD_COMPANIES.keys
  # ["switch", "visa", "diners_club", "master", "forbrugsforeningen", "dankort", 
  #    "laser", "american_express", "solo", "jcb", "discover", "maestro"]
  def credit_card_type
    @cc.valid?
    @cc.type
  end

  def self.refund(amount, old_transaction_id, agent=nil)
    amount = amount.to_f
    # Lock transaction, so no one can use this record while we refund this member.
    old_transaction = Transaction.find_by_uuid old_transaction_id, :lock => true
    trans = Transaction.new
    if amount <= 0.0
      return { :message => "Credit amount must be a positive number.", :code => '9787' }
    elsif old_transaction.amount == amount
      trans.transaction_type = "refund"
    elsif old_transaction.amount > amount
      trans.transaction_type = "credit"
    end
    if old_transaction.amount_available_to_refund < amount
      return { :message => "Cant credit more $ than the original transaction amount", :code => '9788' }
    end
    trans.prepare(old_transaction.member, old_transaction.credit_card, amount, 
        old_transaction.member.terms_of_membership.payment_gateway_configuration)
    answer = trans.process
    if trans.success?
      old_transaction.refunded_amount = old_transaction.refunded_amount + amount
      old_transaction.save
      Auditory.audit(agent, trans, "Credit success $#{amount}", old_transaction.member, Settings.operation_types.credit)
      Communication.deliver!(:refund, old_transaction.member)
    end
    answer
  end

  def amount_available_to_refund
    amount - refunded_amount
  end

  private

    def credit
      if payment_gateway_configuration.nil?
        { :message => "Payment gateway not found.", :code => "9999" }
      else
        verify_card
        if @cc.valid?
          load_gateway
          a = (amount.to_f * 100)
          credit_response=@gateway.credit(a, @cc, @options)
          save_response(credit_response)
        else
          credit_card_invalid
        end
      end
    end

    def refund
      if payment_gateway_configuration.nil?
        { :message => "Payment gateway not found.", :code => "9999" }
      else
        verify_card
        if @cc.valid?
          load_gateway
          a = (amount.to_f * 100)
          refund_response=@gateway.refund(a, self.response_transaction_id, @options)
          save_response(refund_response)
        else
          credit_card_invalid
        end
      end
    end    

    # Process only sale operations
    def sale
      if payment_gateway_configuration.nil?
        { :message => "Payment gateway not found.", :code => "9999" }
      elsif amount.to_f == 0.0
        { :message => "Transaction success. Amount $0", :code => "000" }
      else
        verify_card
        if @cc.valid?
          load_gateway
          a = (amount.to_f * 100)
          purchase_response = @gateway.purchase(a, @cc, @options)
          save_response(purchase_response)
        else
          credit_card_invalid
        end
      end
    end

    def credit_card_invalid
      errors = @cc.errors.collect {|attr, message| "#{attr}: #{message}" }.join('\n')
      message = "Credit card not valid: #{errors}"
      self.response_code = "9332"
      self.response_result = message
      self.save
      { :message => message, :code => "9332" }
    end

    def save_response(answer)
      self.response = answer
      self.response_transaction_id=answer.params['transaction_id']
      self.response_auth_code=answer.params['auth_code']
      self.response_code=answer.params['error_code']
      self.response_result=answer.message
      save

      if response.params[:duplicate]=="true"
        # we keep this if, just because it was on Litle version (compatibility).
        # MeS seems to not send this param
        {:message=>"Duplicated Transaction: #{response.params[:response]}",:code=>"900"}
      elsif response.success?
        unless self.credit_card.nil?
          self.credit_card.accepted_on_billing
        end
        {:message=>response.message,:code=>"000"}
      else
        {:message=>"Error: " + response.message,:code=>response_code}
      end      
    end

    def verify_card
      ActiveMerchant::Billing::CreditCard.require_verification_value = false
      @cc ||= ActiveMerchant::Billing::CreditCard.new(
        :number     => number,
        :month      => expire_month,
        :year       => expire_year,
        :first_name => first_name,
        :last_name  => last_name
      )
    end

    def load_gateway(recurrent = false)
      if production?
        ActiveMerchant::Billing::Base.mode = :production
      else
        ActiveMerchant::Billing::Base.mode = :test
      end
      if mes?
        @gateway = ActiveMerchant::Billing::MerchantESolutionsGateway.new(
            :login    => login,
            :password => password,
            :merchant_key => merchant_key
          )
      elsif litle?
        # TODO: add litle configuration!!!
      end
      @options = {
        :order_id => invoice_number,
        :customer => member_id,
        :billing_address => {
          :name     => "#{first_name} #{last_name}",
          :address1 => address,
          :city     => city,
          :state    => state,
          :zip      => zip.gsub(/[a-zA-Z-]/, ''),
          :phone    => phone_number
          }
        }
      @options[:moto_ecommerce_ind] = 2 if recurrent
    end

end
