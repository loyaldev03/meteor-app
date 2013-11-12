class CreditCardDifferentGatewaysException < Exception
  def initialize(data)
    @data = data
  end
end