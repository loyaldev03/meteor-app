class FirstDataTransaction < Transaction

  def member=(member)
    super(member)
    self.invoice_number = member.id
  end

  def self.store!(am_credit_card, pgc)
  	ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password }
    gateway = ActiveMerchant::Billing::FirstdataE4Gateway.new(login_data)
    gateway.store(am_credit_card).authorization
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end
  
  private

    def credit_card_token
      self.token
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        self.response_code = answer.params['bank_resp_code']
      end
      self.response_transaction_id = answer.authorization
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      login_data = { :login => login, :password => password }
      @gateway = ActiveMerchant::Billing::FirstdataE4Gateway.new(login_data)
    end
end