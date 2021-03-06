class TrustCommerceTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = user.id
  end

  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data  = { login: pgc.login, password: pgc.password }
    gateway     = ActiveMerchant::Billing::TrustCommerceGateway.new(login_data)
    answer      = nil
    time_elapsed = Benchmark.ms do
      answer = gateway.store(am_credit_card)
    end
    logger.info "AM::Store::Answer (#{pgc.gateway} took #{time_elapsed}ms) => " + answer.inspect
    raise answer.params['status'] unless answer.success?    
    answer.params["billingid"] if answer.params
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end
  
  def new_chargeback!(sale_transaction, args)
    trans = TrustCommerceTransaction.find_by(response: args.to_json)
    if trans.nil?
      chargeback_amount = -args[:transaction_amount].to_f
      operation_description = "Chargeback processed $#{chargeback_amount}"
      self.transaction_type = "chargeback"
      self.response = args
      self.prepare(sale_transaction.user, sale_transaction.credit_card, chargeback_amount, 
                    sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, nil, Settings.operation_types.chargeback)
      self.response_result = args[:reason]
      self.response_code ='000'
      self.success = true
      self.membership_id = sale_transaction.membership_id
      self.created_at = args[:adjudication_date]
      self.save!
      update_gateway_cost
      Auditory.audit(nil, self, operation_description, sale_transaction.user, Settings.operation_types.chargeback)
    end
  end

  private
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
      login_data = { login: login, password: password }
      @gateway = ActiveMerchant::Billing::TrustCommerceGateway.new(login_data)
    end
end
