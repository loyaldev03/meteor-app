class PayeezyTransaction < Transaction

  delegate :additional_attributes, to: :payment_gateway_configuration

  def user=(user)
    super(user)
    # IMPORTANT: Payeezy only saves up to 20 characters in the invoice number
    self.invoice_number = user.id || user.email
  end

  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data = { 
      apikey: pgc.login,
      apisecret: pgc.password,
      token: pgc.merchant_key,
      js_security_key: pgc.additional_attributes['js_security_key'], 
      ta_token: pgc.additional_attributes['ta_token']
    }
    gateway     = ActiveMerchant::Billing::PayeezyGateway.new(login_data)
    answer      = nil
    am_credit_card.verification_value = 123 # (for cvv validation) According to Jay from Payeezy we can set any numeric value since it doesn't matter.
    time_elapsed = Benchmark.ms do
      answer = gateway.store(am_credit_card, login_data)
    end
    logger.info "AM::Store::Answer (#{pgc.gateway} took #{time_elapsed}ms) => " + answer.inspect
    raise answer.params['Error']['messages'].first['code'] if answer.params and answer.params['status'] != 'success'
    answer.params['token']['value']
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end
  
  def new_chargeback!(sale_transaction, args)
    trans = PayeezyTransaction.find_by(response: args.to_hash.to_json)
    if trans.nil?
      if (args['Chargeback Status'] == 'OPEN' || (args['Chargeback Status'] == 'CLOSED' && args['Chargeback Category'] == 'PRE-ARBITRATION'))
        chargeback_amount     = -args['Chargeback Amount'].to_f
        operation_type        = Settings.operation_types.chargeback
        operation_description = "Chargeback processed $#{chargeback_amount}"
        chargeback_type       = 'chargeback'
      elsif args['Chargeback Status'] == 'REVERSED'
        chargeback_amount     = args['Chargeback Amount'].to_f
        operation_type        = Settings.operation_types.chargeback_rebutted
        operation_description = "Rebutted Chargeback processed $#{chargeback_amount}"
        chargeback_type       = 'rebutted_chargeback'
      elsif args['Chargeback Status'] == 'CLOSED' && args['Chargeback Category'] == 'DEBITED'
        raise NonReportableException.new
      elsif args['Chargeback Status'] != 'CLOSED'
        raise "Wrong status received: Status: #{args['Chargeback Status']}}"
      end
      
      self.transaction_type   = chargeback_type
      self.response           = args.to_hash.to_json
      self.prepare(sale_transaction.user, sale_transaction.credit_card, chargeback_amount, 
                    sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, nil, operation_type)
      self.response_auth_code = args['Authorization Code']
      self.response_result    = args['Chargeback Reason Code'] + '-' + args['Chargeback Description']
      self.response_code      = '000'
      self.success            = true
      self.membership_id      = sale_transaction.membership_id
      self.created_at         = args['Received Date'].to_time
      self.save!
      update_gateway_cost
      Auditory.audit(nil, self, operation_description, sale_transaction.user, operation_type)
    end
  end

  private
    def credit_card_token
      # visa|sebastian sebastian|0318|#{response.params['token']['token_data']['value']}
      [ ActiveMerchant::Billing::PayeezyGateway::CREDIT_CARD_BRAND[cc_type], 
        first_name + ' ' + last_name,
        ("%.2d" % expire_month).to_s + (expire_year % 100).to_s,
        token
      ].join('|')
    end
    
    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        # self.response_code = (['Not Processed', 'Declined'].include? answer.params['transaction_status'] ? answer.params['Error']['messages'].map{|x| x['code']} : answer.params['transaction_status'])
        self.response_code = if answer.params['transaction_status'] == 'declined'
          answer.params['bank_resp_code'].present? ? answer.params['bank_resp_code'] : answer.params['gateway_resp_code']
        else
          answer.params['transaction_status']
        end
        self.response_auth_code = answer.authorization
        self.response_transaction_id = "#{answer.params['transaction_id']}|#{answer.params['transaction_tag']}|direct_debit"
      end
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway
      login_data = { apikey: login, apisecret: password, token: merchant_key, js_security_key: additional_attributes['js_security_key'], ta_token: additional_attributes['ta_token'] }
      @gateway = ActiveMerchant::Billing::PayeezyGateway.new(login_data)
      @options[:level2] = {}
      @options[:level2][:tax1_amount] = '25'
    end
end
