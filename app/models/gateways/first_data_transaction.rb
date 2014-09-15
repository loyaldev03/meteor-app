class FirstDataTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = user.id
  end

  def self.store!(am_credit_card, pgc)
  	ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password }
    gateway = ActiveMerchant::Billing::FirstdataE4Gateway.new(login_data)
    answer = gateway.store(am_credit_card)
    raise answer.message unless answer.success?    
    answer.params["transarmor_token"] if answer.params
  rescue Exception => e
    logger.error "AM::Store::Answer => " + answer.inspect
    raise e
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = [sale_transaction.response_auth_code, sale_transaction.response_transaction_id, sale_transaction.amount.to_s.gsub(".","")].join(";")
  end
  
  private

    def credit_card_token
      [self.token, self.cc_type, self.first_name, self.last_name, self.expire_month, self.expire_year].join(";")
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        self.response_code = answer.params['bank_resp_code']
        self.response_auth_code = answer.params['authorization_num']
        self.response_transaction_id = answer.params['transaction_tag']
      end
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      login_data = { :login => login, :password => password }
      @gateway = ActiveMerchant::Billing::FirstdataE4Gateway.new(login_data)
    end
end