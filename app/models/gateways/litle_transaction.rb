class LitleTransaction < Transaction

  def member=(member)
    super(member)
    # MeS supports only 17 characters on order_id
    # litle had "#{Date.today}-#{order_mark}#{@transaction.member_id}"
    self.invoice_number = member.id
  end

  # answer credit card token
  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( pgc.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password, :merchant_key => pgc.merchant_key, :merchant_id => "" }
    token, answer = nil, nil
    gateway = ActiveMerchant::Billing::LitleGateway.new(login_data)
    answer = gateway.store(am_credit_card)
    raise answer.params['litleOnlineResponse']['response'] unless answer.success?
    token = answer.params['litleOnlineResponse']['litleToken']
    logger.error "AM::Store::Answer => " + answer.inspect
    token
  end


  private

    def save_response(answer)
      self.response = answer
      if answer.params 
        self.response_transaction_id=answer.params['litleOnlineResponse']['litleTxnId']
        self.response_auth_code=answer.params['auth_code']
        self.response_code=answer.params['litleOnlineResponse']['response']
      end
      self.response_result=answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      @login_data = { :login => login, :password => password, :merchant_key => merchant_key, :merchant_id => "" }
      @gateway = ActiveMerchant::Billing::LitleGateway.new(@login_data)
      # @options.merge!({
      #   :report_group => report_group,
      #   :custom_billing => {
      #     :descriptor => descriptor_name,
      #     :phone => descriptor_phone
      #   }
      # })
    end

end
