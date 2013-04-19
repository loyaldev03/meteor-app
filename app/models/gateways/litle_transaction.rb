class LitleTransaction < Transaction

  def member=(member)
    super(member)
    # MeS supports only 17 characters on order_id
    # litle had "#{Date.today}-#{order_mark}#{@transaction.member_id}"
    self.invoice_number = member.id
  end

  # answer credit card token
  # AM::Store::Answer => #<ActiveMerchant::Billing::Response:0x000000083fdc40 @params={"litleOnlineResponse"=>{"message"=>"Valid Format", "response"=>"0", "version"=>"8.16", "xmlns"=>"http://www.litle.com/schema", "registerTokenResponse"=>{"customerId"=>"", "id"=>"", "reportGroup"=>"Default Report Group", "litleTxnId"=>"630745122415368266", "litleToken"=>"1111222233334444", "response"=>"000", "responseTime"=>"2013-04-08T16:54:24", "message"=>"Approved"}}}, @message="Approved", @success=true, @test=true, @authorization="1111222233334444", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>
  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( pgc.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password, :merchant_key => pgc.merchant_key, :merchant_id => "" }
    token, answer = nil, nil
    gateway = ActiveMerchant::Billing::LitleGateway.new(login_data)
    answer = gateway.store(am_credit_card)
    raise answer.params['litleOnlineResponse']['response'] unless answer.success?
    logger.error "AM::Store::Answer => " + answer.inspect
    answer.params['litleOnlineResponse']['registerTokenResponse']['litleToken']
  end


  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "credit"
  end 

  private

    def credit_card_token
      token = ActiveMerchant::Billing::LitleGateway::LitleCardToken.new(
        :token              => self.token,
        :month              => self.expire_month,
        :year               => self.expire_year,
        :brand              => self.cc_type # ,
        # :verification_value => '123'
      )
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
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
