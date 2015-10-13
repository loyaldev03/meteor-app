class AuthorizeNetTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = self.user_id
  end

  # answer credit card token
  def self.store!(am_credit_card, pgc)
    Base64::encode64(Encryptor.encrypt(am_credit_card.number, key: Digest::SHA256.hexdigest(Settings.xxxyyyzzz), algorithm: 'bf'))
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end 

  private

    def credit_card_token
      number = Encryptor.decrypt(Base64::decode64(self.token), key: Digest::SHA256.hexdigest(Settings.xxxyyyzzz), algorithm: 'bf')
      CreditCard.am_card(number, expire_month, expire_year, first_name, last_name)
    end

    # #<ActiveMerchant::Billing::Response:0x000000085d7458 @params={"response_code"=>3, "response_reason_code"=>"6", "response_reason_text"=>"(TESTMODE) The credit card number is invalid.", "avs_result_code"=>"P", "transaction_id"=>"0", "card_code"=>"", "action"=>"AUTH_CAPTURE"}, @message="(TESTMODE) The credit card number is invalid", @success=false, @test=true, @authorization="0", @fraud_review=false, @avs_result={"code"=>"P", "message"=>"Postal code matches, but street address not verified.", "street_match"=>nil, "postal_match"=>"Y"}, @cvv_result={"code"=>nil, "message"=>nil}>
    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      logger.error answer.inspect
      if answer.params
        self.response_transaction_id=answer.params['transaction_id']
        # self.response_auth_code=answer.params['auth_code']
        self.response_code=answer.params['response_code']
      end
      self.response_result=answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      @login_data = { login: login, password: password, test: !Rails.env.production? }
      @gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new @login_data
      @options[:card_number] = credit_card_token.number
    end

end
