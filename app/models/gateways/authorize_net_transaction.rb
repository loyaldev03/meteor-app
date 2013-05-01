class AuthorizeNetTransaction < Transaction
  SECRET_KEY_FOR_TOKEN = "7faf4f991bc44841a00423b8db9602bb"

  def member=(member)
    super(member)
    self.invoice_number = self.member_id
  end

  # answer credit card token
  # AM::Store::Answer => #<ActiveMerchant::Billing::Response:0x000000083fdc40 @params={"litleOnlineResponse"=>{"message"=>"Valid Format", "response"=>"0", "version"=>"8.16", "xmlns"=>"http://www.litle.com/schema", "registerTokenResponse"=>{"customerId"=>"", "id"=>"", "reportGroup"=>"Default Report Group", "litleTxnId"=>"630745122415368266", "litleToken"=>"1111222233334444", "response"=>"000", "responseTime"=>"2013-04-08T16:54:24", "message"=>"Approved"}}}, @message="Approved", @success=true, @test=true, @authorization="1111222233334444", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>
  def self.store!(am_credit_card, pgc)
    Encryptor.encrypt(am_credit_card.number, :key => Digest::SHA256.hexdigest(SECRET_KEY_FOR_TOKEN))
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
  end 

  private

    def credit_card_token
      number = Encryptor.encrypt(self.token, :key => Digest::SHA256.hexdigest(SECRET_KEY_FOR_TOKEN))
      CreditCard.am_card(number, expire_month, expire_year, first_name, last_name)
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
      @login_data = { :login => login, :password => password, :test => !pgc.production? }
      @gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new @login_data
    end

end
