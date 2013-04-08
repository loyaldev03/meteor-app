class MerchantESolutionsTransaction < Transaction

  def member=(member)
    super(member)
    # MeS supports only 17 characters on order_id
    # litle had "#{Date.today}-#{order_mark}#{@transaction.member_id}"
    self.invoice_number = member.id
  end

  # answer credit card token
  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( pgc.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password, :merchant_key => pgc.merchant_key }
    gateway = ActiveMerchant::Billing::MerchantESolutionsGateway.new(login_data)
    answer = gateway.store(am_credit_card)
    raise answer.params['error_code'] unless answer.success?
    token = answer.params['transaction_id']  
    logger.error "AM::Store::Answer => " + answer.inspect
    token
  end

  def self.new_chargeback(sale_transaction, args)
    trans = MerchantESolutionsTransaction.new
    trans.transaction_type = "chargeback"
    trans.refund_response_transaction_id = sale_transaction.response_transaction_id
    trans.prepare(sale_transaction.member, sale_transaction.credit_card, args[:transaction_amount], 
                  sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id)
    trans.response_auth_code=args[:auth_code]
    trans.response_result=args[:reason]
    trans.response_code=args[:reason_code]
    trans.response = args
    trans.save
    Auditory.audit(nil, trans, "Chargeback processed $#{trans.amount}", sale_transaction.member, Settings.operation_types.chargeback)
  end

  private

    def save_response(answer)
      self.response = answer
      self.response_transaction_id=answer.params['transaction_id']
      self.response_auth_code=answer.params['auth_code']
      self.response_code=answer.params['error_code']
      self.response_result=answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      @login_data = { :login => login, :password => password, :merchant_key => merchant_key }
      @gateway = ActiveMerchant::Billing::MerchantESolutionsGateway.new(@login_data)
      @options[:customer] = member_id 
      @options[:moto_ecommerce_ind] = 2 if recurrent
    end

end
