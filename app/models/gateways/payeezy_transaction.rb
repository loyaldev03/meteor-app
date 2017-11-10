class PayeezyTransaction < Transaction

  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data = { 
      apikey: pgc.login,
      apisecret: pgc.password,
      token: pgc.merchant_key
    }
    gateway     = ActiveMerchant::Billing::PayeezyGateway.new(login_data)
    answer      = nil
    time_elapsed = Benchmark.ms do
      answer = gateway.authorize(0,am_credit_card)
    end
    logger.info "AM::Store::Answer (#{pgc.gateway} took #{time_elapsed}ms) => " + answer.inspect
    raise answer.error_code if answer.params['results'] and answer.params['transaction_status'] != 'approved'
    answer.params['token']['token_data']['value']
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end
  
  def new_chargeback!(sale_transaction, args)
    trans = PayeezeTransaction.find_by(response: args.to_json)
    if trans.nil?
      chargeback_amount       = -args['Chargeback Amount'].to_f
      self.transaction_type   = "chargeback"
      self.response           = args
      self.prepare(sale_transaction.user, sale_transaction.credit_card, chargeback_amount, 
                    sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, nil, Settings.operation_types.chargeback)
      self.response_auth_code = args['Authorization Code']
      self.response_result    = args['Chargeback Reason Code']
      self.response_code      = '000'
      self.success            = true
      self.membership_id      = sale_transaction.membership_id
      self.created_at         = args['Adjustment Date']
      self.save!
      Auditory.audit(nil, self, "Chargeback processed $#{chargeback_amount}", sale_transaction.user, Settings.operation_types.chargeback)
    end
  end

  private
    def credit_card_token
      # visa|sebastian sebastian|0318|#{response.params['token']['token_data']['value']}
      [ cc_type, 
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
      login_data = { apikey: login, apisecret: password, token: merchant_key }
      @gateway = ActiveMerchant::Billing::PayeezyGateway.new(login_data)
    end
end