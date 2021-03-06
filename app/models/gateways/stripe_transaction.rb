class StripeTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = user.id
  end

  def self.store!(am_credit_card, pgc, user)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    gateway = ActiveMerchant::Billing::StripeGateway.new login: pgc.login
    params  = user.stripe_id ? {customer: user.stripe_id, :set_default => true} : {email: user.email, :set_default => true}
    answer  = nil
    time_elapsed = Benchmark.ms do
      answer = gateway.store(am_credit_card, params)
    end
    logger.info "AM::Store::Answer (#{pgc.gateway} took #{time_elapsed}ms) => " + answer.inspect
    raise answer.params["error"]["code"] if answer.params["error"]
    if user.stripe_id
      answer.params["fingerprint"]
    else
      user.stripe_id = answer.params["id"]
      answer.params["sources"]["data"].first["fingerprint"]
    end
  end

  def fill_transaction_type_for_credit(sale_transaction)
    self.transaction_type = "refund"
    self.refund_response_transaction_id = sale_transaction.response_transaction_id
  end

  private

    def credit_card_token
      nil
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        self.response_code = answer.params['status'] == 'succeeded' ? answer.params['status'] : answer.params['error']['code']
        self.response_transaction_id = answer.params['id']
      end
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway
      @gateway = ActiveMerchant::Billing::StripeGateway.new login: login
      @options[:customer] = stripe_customer_id
    end
end
