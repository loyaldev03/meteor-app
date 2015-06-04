class TrustCommerceTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = user.id
  end

  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data = { :login => pgc.login, :password => pgc.password }
    gateway = ActiveMerchant::Billing::TrustCommerceGateway.new(login_data)
    answer = gateway.store(am_credit_card)
    raise answer.message unless answer.success?    
    answer.params["billingid"] if answer.params
  rescue Exception => e
    logger.error "AM::Store::Answer => " + answer.inspect
    raise e
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "credit"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end
  
  private
    #HACK: credit method is used by other GWs. they don't use the response id for credits. THat's why I'm overwriting this method only for TSYS
    def credit
      if payment_gateway_configuration.nil?
        save_custom_response({ :message => "Payment gateway not found.", :code => Settings.error_codes.not_found })
      elsif self.token.nil? or self.token.size < 4
        save_custom_response({ :code => Settings.error_codes.credit_card_blank_without_grace, :message => "Credit card is blank we wont bill" })
      else
        debugger
        load_gateway
        credit_response=@gateway.credit(amount_to_send, refund_response_transaction_id, @options)
        save_response(credit_response)
      end
    rescue Timeout::Error
      save_custom_response({ :code => Settings.error_codes.payment_gateway_time_out, :message => I18n.t('error_messages.payment_gateway_time_out') })
    rescue Exception => e
      response = save_custom_response({ :code => Settings.error_codes.payment_gateway_error, :message => I18n.t('error_messages.airbrake_error_message') })
      Auditory.report_issue("Transaction::Credit", e, {:user => self.user.inspect, :transaction => "ID: #{self.id}, amount: #{self.amount}, response: #{self.response}"})
      response
    end

    def credit_card_token
      token
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        self.response_code = (answer.params['status'] == "decline" ? answer.params['declinetype'] : answer.params['status'])
        self.response_auth_code = answer.params['authcode']
        self.response_transaction_id = answer.params['transid']
      end
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      login_data = { :login => login, :password => password }
      @gateway = ActiveMerchant::Billing::TrustCommerceGateway.new(login_data)
    end
end