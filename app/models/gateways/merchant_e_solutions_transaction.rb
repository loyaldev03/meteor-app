class MerchantESolutionsTransaction < Transaction

  def user=(user)
    super(user)
    # MeS supports only 17 characters on order_id
    # litle had "#{Date.today}-#{@transaction.user_id}"
    self.invoice_number = user.id
  end

  # answer credit card token
  # AM::Store::Answer => #<ActiveMerchant::Billing::Response:0x0000000718c228 @params={"transaction_id"=>"1e9be6d0b4303619897d20524de49372", "error_code"=>"000", "auth_response_text"=>"Card Data Stored"}, @message="This transaction has been approved", @success=true, @test=true, @authorization="1e9be6d0b4303619897d20524de49372", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>
  def self.store!(am_credit_card, pgc)
    ActiveMerchant::Billing::Base.mode = ( Rails.env.production? ? :production : :test )
    login_data  = { login: pgc.login, password: pgc.password, merchant_key: pgc.merchant_key }
    gateway     = ActiveMerchant::Billing::MerchantESolutionsGateway.new(login_data)
    answer      = nil
    time_elapsed = Benchmark.ms do
      answer = gateway.store(am_credit_card)
    end
    logger.info "AM::Store::Answer => (#{pgc.gateway} took #{time_elapsed}ms)" + answer.inspect
    raise answer.params['error_code'] unless answer.success?
    answer.params['transaction_id']
  end

  def new_chargeback!(sale_transaction, args)
    trans = MerchantESolutionsTransaction.find_by(response: args.to_json)
    if trans.nil?
      if args[:adjudication_date].last == '+'
        chargeback_amount = args[:transaction_amount].to_f
        operation_description = "Rebutted Chargeback processed $#{chargeback_amount}"
        chargeback_operation_type = Settings.operation_types.chargeback_rebutted
        chargeback_success = true
      else
        chargeback_amount = -args[:transaction_amount].to_f
        operation_description = "Chargeback processed $#{chargeback_amount}"
        chargeback_operation_type = Settings.operation_types.chargeback
        chargeback_success = true
      end

      self.transaction_type = "chargeback"
      self.response = args
      self.prepare(sale_transaction.user, sale_transaction.credit_card, chargeback_amount, 
                    sale_transaction.payment_gateway_configuration, sale_transaction.terms_of_membership_id, nil, chargeback_operation_type)
      self.response_auth_code = args[:auth_code]
      self.response_result = args[:reason]
      self.response_code ='000'
      self.success = chargeback_success
      self.membership_id = sale_transaction.membership_id
      self.created_at = args[:adjudication_date]
      self.save!
      Auditory.audit(nil, self, operation_description, sale_transaction.user, chargeback_operation_type)
    end
  end

  def fill_transaction_type_for_credit(sale_transaction)
    if sale_transaction.amount.to_f == amount.abs.to_f
      self.transaction_type = "refund"
      self.refund_response_transaction_id = sale_transaction.response_transaction_id
    elsif sale_transaction.amount.to_f > amount.abs.to_f
      self.transaction_type = "credit"
    end
  end    
  
  private

    def credit_card_token
      self.token
    end

    def save_response(answer)
      self.response = answer
      self.success = answer.success?
      if answer.params
        self.response_transaction_id=answer.params['transaction_id']
        self.response_auth_code=answer.params['auth_code']
        self.response_code=answer.params['error_code']
      end
      self.response_result=answer.message
      save
      super(answer)
    end

    def load_gateway(recurrent = false)
      @login_data = { login: login, password: password, merchant_key: merchant_key }
      @gateway = ActiveMerchant::Billing::MerchantESolutionsGateway.new(@login_data)
      @options[:customer] = user_id 
      @options[:moto_ecommerce_ind] = 2 if recurrent
    end

end
