class Transaction < ActiveRecord::Base
  belongs_to :member
  belongs_to :payment_gateway_configuration
  belongs_to :decline_strategy
  belongs_to :credit_card

  attr_encrypted :encrypted_number, :key => :encryption_key, :encode => true, :algorithm => 'bf'

  def encryption_key
    "reibel3y5estrada8"
  end 

  def member=(member)
    member_id = member.id
    # MeS supports only 17 characters on order_id
    invoice_number = member.id
    first_name = member.first_name
    last_name = member.last_name
    phone_number = member.phone_number
    email = member.email
    address_line = member.address
    city = member.city
    state = member.state
    zip = member.zip
  end

  def credit_card=(credit_card)
    credit_card_id = credit_card.id
    encrypted_number = credit_card.encrypted_number
    expire_month = credit_card.expire_month
    expire_year = credit_card.expire_year
  end

  def payment_gateway_configuration=(pgc)
    payment_gateway_configuration_id = pgc.id
    report_group = pgc.report_group
    merchant_key = pgc.merchant_key
    login = pgc.login
    password = pgc.password
    mode = pgc.mode
    descriptor_name = pgc.descriptor_name
    descriptor_phone = pgc.descriptor_phone
    order_mark = pgc.order_mark
    gateway = pgc.gateway
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

  def process
    case transaction_type
      when "sale"
        sale
      when "authorization"
        authorization
      when "capture"
        capture
      when "credit"
        credit
      when "refund"
        refund
      when "void"
        void
      when "authorization_capture"
        authorization_capture
      else
        { :message=>"operation not supported",:code=> 902 }
    end
  end  

  def production?
    mode == "production"
  end

  def mes?
    gateway == "mes"
  end

  def litle?
    gateway == "litle"
  end


  # TODO: find out if this transaction is a decline
  # decline_strategy_id: nil

  private
    # Process only sale operations
    def sale
      if payment_gateway_configuration.nil?
        { :message => "Payment gateway not found.", :code => "9999" }
      elsif amount.to_f == 0.0
        { :message => "Transaction success. Amount $0", :code => "000" }
      else
        verify_card
        if @credit_card.valid?
          load_gateway
          a = (amount.to_f * 100)
          purchase_response = @gateway.purchase(a, @credit_card, @options)
          save_response(purchase_response)
        else
          { :message => "Credit card not valid: #{@credit_card.errors}", :code => "9332" }
        end
      end
    end

    def save_response(answer)
      response = answer
      response_transaction_id=answer.params['transaction_id']
      response_auth_code=answer.params['auth_code']
      response_code=answer.params['error_code']
      response_result=answer.message
      save

      if response.params[:duplicate]=="true"
        # we keep this if, just because it was on Litle version (compatibility).
        # MeS seems to not send this param
        {:message=>"Duplicated Transaction: #{response.params[:response]}",:code=>"900"}
      elsif response.success?
        self.credit_card.last_successful_bill_date = DateTime.now
        self.credit_card.save
        {:message=>response.message,:code=>"000"}
      else
        {:message=>"Error: " + response.message,:code=>response.params['error_code']}
      end      
    end

    def verify_card
      ActiveMerchant::Billing::CreditCard.require_verification_value = false
      @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
        :number     => cc_number,
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
          :phone    => phone
          }
        }
      @options[:moto_ecommerce_ind] = 2 if recurrent
    end

end
