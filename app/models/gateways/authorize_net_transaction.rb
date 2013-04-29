class AuthorizeNetTransaction < Transaction

  def member=(member)
    super(member)
    self.invoice_number = self.member_id
  end


  # simulate credit method from AM
  def credit
  end

  # simulate refund method from AM
  def refund
  end

  # simulate purchase method from AM
  def purchase(pamount, customer_profile_id, options = {})
    gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new :login => login, :password => password
    gateway.create_customer_profile_transaction( :transaction => { 
                  :type => :auth_capture, :customer_profile_id => customer_profile_id, 
                  :amount => pamount, :order => { :invoice_number => invoice_number }
                })
  end

  # answer credit card token
  # AM::Store::Answer =>  => #<ActiveMerchant::Billing::Response:0x0000000752e778 @params={"messages"=>{"result_code"=>"Ok", "message"=>{"code"=>"I00001", "text"=>"Successful."}}, "customer_profile_id"=>"18048580", "customer_payment_profile_id_list"=>nil, "customer_shipping_address_id_list"=>nil, "validation_direct_response_list"=>nil}, @message="Successful.", @success=true, @test=true, @authorization="18048580", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}> 
  def self.store!(am_credit_card, pgc, email)
    ######
    # ActiveMerchant::Billing::Base.mode = ( pgc.production? ? :production : :test )
    # answer = gateway.create_customer_profile(:profile => { :email => email }, :payment_profile => { :credit_card => am_credit_card })
    # answer = gateway.create_customer_payment_profile(:profile => { :email => email, :payment_profile => { :credit_card => am_credit_card } })

    ###### 
    # gateway = AuthorizeCim.new :login => pgc.login, :key => pgc.password, :endpoint => :test
    # answer = gateway.create_customer_profile(:email => email)
    # if answer.success?
    #   answer = gateway.create_customer_payment_profile({
    #                 :customer_profile_id  => answer.params['customer_profile_id'],
    #                 :payment_profile      => {
    #                   :payment => { 
    #                     :credit_card => { 
    #                       :card_number      => am_credit_card.number,
    #                       :expiration_date  => ("%s%02d" % [am_credit_card.year.to_s, am_credit_card.month])
    #                     }
    #                   }
    #                 }, 
    #                 :validation_mode => 'none' 
    #               })
    # end

    logger.error "AM::Store::Answer => " + answer.inspect
    raise answer.message unless answer.success?
    answer.params['customer_profile_id']
  end


  def fill_transaction_type_for_credit(sale_transaction)
    # self.transaction_type = "credit"
  end 

  private

    def credit_card_token
      self.token
    end

    def save_response(answer)
      # self.response = answer
      # self.success = answer.success?
      # if answer.params
      #   self.response_transaction_id=answer.params['litleOnlineResponse']['litleTxnId']
      #   self.response_auth_code=answer.params['auth_code']
      #   self.response_code=answer.params['litleOnlineResponse']['response']
      # end
      # self.response_result=answer.message
      # save
      # super(answer)
    end

    def load_gateway(recurrent = false)
      @gateway = self
    end

end
