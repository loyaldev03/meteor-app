class StripeTransaction < Transaction

  def user=(user)
    super(user)
    self.invoice_number = user.id
  end

  # Answer for new customer => #<ActiveMerchant::Billing::Response:0x00000009add528 @params={"object"=>"customer", "created"=>1438277195, "id"=>"cus_6hkIfnU0HzB6s7", "livemode"=>false, "description"=>nil, "email"=>"sebastian+new@xagax.com", "delinquent"=>false, "metadata"=>{}, "subscriptions"=>{"object"=>"list", "total_count"=>0, "has_more"=>false, "url"=>"/v1/customers/cus_6hkIfnU0HzB6s7/subscriptions", "data"=>[]}, "discount"=>nil, "account_balance"=>0, "currency"=>nil, "sources"=>{"object"=>"list", "total_count"=>1, "has_more"=>false, "url"=>"/v1/customers/cus_6hkIfnU0HzB6s7/sources", "data"=>[{"id"=>"card_16UKnfHrcw1MEee7Gx3fyQgJ", "object"=>"card", "last4"=>"4242", "brand"=>"Visa", "funding"=>"credit", "exp_month"=>8, "exp_year"=>2020, "fingerprint"=>"oR2du9mINXNGpmF4", "country"=>"US", "name"=>"sebas sebast", "address_line1"=>nil, "address_line2"=>nil, "address_city"=>nil, "address_state"=>nil, "address_zip"=>nil, "address_country"=>nil, "cvc_check"=>nil, "address_line1_check"=>nil, "address_zip_check"=>nil, "tokenization_method"=>nil, "dynamic_last4"=>nil, "metadata"=>{}, "customer"=>"cus_6hkIfnU0HzB6s7"}]}, "default_source"=>"card_16UKnfHrcw1MEee7Gx3fyQgJ"}, @message="Transaction approved", @success=true, @test=true, @authorization="cus_6hkIfnU0HzB6s7", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}> 
  # Answer for old customer => #<ActiveMerchant::Billing::MultiResponse:0x00000009b97658 @responses=[#<ActiveMerchant::Billing::Response:0x00000009ba4c40 @params={"id"=>"card_16UKpkHrcw1MEee7JNpht7k5", "object"=>"card", "last4"=>"4242", "brand"=>"Visa", "funding"=>"credit", "exp_month"=>8, "exp_year"=>2021, "fingerprint"=>"oR2du9mINXNGpmF4", "country"=>"US", "name"=>"sebas sebast", "address_line1"=>nil, "address_line2"=>nil, "address_city"=>nil, "address_state"=>nil, "address_zip"=>nil, "address_country"=>nil, "cvc_check"=>nil, "address_line1_check"=>nil, "address_zip_check"=>nil, "tokenization_method"=>nil, "dynamic_last4"=>nil, "metadata"=>{}, "customer"=>"cus_6hkIfnU0HzB6s7"}, @message="Transaction approved", @success=true, @test=false, @authorization="card_16UKpkHrcw1MEee7JNpht7k5", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>, #<ActiveMerchant::Billing::Response:0x00000009bc15c0 @params={"object"=>"customer", "created"=>1438277195, "id"=>"cus_6hkIfnU0HzB6s7", "livemode"=>false, "description"=>nil, "email"=>"sebastian+new@xagax.com", "delinquent"=>false, "metadata"=>{}, "subscriptions"=>{"object"=>"list", "total_count"=>0, "has_more"=>false, "url"=>"/v1/customers/cus_6hkIfnU0HzB6s7/subscriptions", "data"=>[]}, "discount"=>nil, "account_balance"=>0, "currency"=>nil, "sources"=>{"object"=>"list", "total_count"=>2, "has_more"=>false, "url"=>"/v1/customers/cus_6hkIfnU0HzB6s7/sources", "data"=>[{"id"=>"card_16UKpkHrcw1MEee7JNpht7k5", "object"=>"card", "last4"=>"4242", "brand"=>"Visa", "funding"=>"credit", "exp_month"=>8, "exp_year"=>2021, "fingerprint"=>"oR2du9mINXNGpmF4", "country"=>"US", "name"=>"sebas sebast", "address_line1"=>nil, "address_line2"=>nil, "address_city"=>nil, "address_state"=>nil, "address_zip"=>nil, "address_country"=>nil, "cvc_check"=>nil, "address_line1_check"=>nil, "address_zip_check"=>nil, "tokenization_method"=>nil, "dynamic_last4"=>nil, "metadata"=>{}, "customer"=>"cus_6hkIfnU0HzB6s7"}, {"id"=>"card_16UKnfHrcw1MEee7Gx3fyQgJ", "object"=>"card", "last4"=>"4242", "brand"=>"Visa", "funding"=>"credit", "exp_month"=>8, "exp_year"=>2020, "fingerprint"=>"oR2du9mINXNGpmF4", "country"=>"US", "name"=>"sebas sebast", "address_line1"=>nil, "address_line2"=>nil, "address_city"=>nil, "address_state"=>nil, "address_zip"=>nil, "address_country"=>nil, "cvc_check"=>nil, "address_line1_check"=>nil, "address_zip_check"=>nil, "tokenization_method"=>nil, "dynamic_last4"=>nil, "metadata"=>{}, "customer"=>"cus_6hkIfnU0HzB6s7"}]}, "default_source"=>"card_16UKpkHrcw1MEee7JNpht7k5"}, @message="Transaction approved", @success=true, @test=true, @authorization="cus_6hkIfnU0HzB6s7", @fraud_review=nil, @avs_result={"code"=>nil, "message"=>nil, "street_match"=>nil, "postal_match"=>nil}, @cvv_result={"code"=>nil, "message"=>nil}>], @primary_response=:first>
  def self.store!(am_credit_card, pgc)
    # TODO
    # if first_time
    #   response = gateway.store(am, { email:"sebastian+new@xagax.com", :set_default => true}) 
    #   response.params["id"] # => "cus_6hkIfnU0HzB6s7"
    # else
    #   response = gateway.store(am, { customer:"cus_6hkIfnU0HzB6s7", :set_default => true})
    #   response.params["customer"]
    # end 
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
        self.response_transaction_id = answer.params['id']
      end
      self.response_result = answer.message
      save
      super(answer)
    end

    def load_gateway
      @login_data = { :login => login }
      @gateway = ActiveMerchant::Billing::StripeGateway.new(@login_data)
      @options[:customer] = token
    end
end