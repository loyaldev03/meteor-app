require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
  end

  test "Falta hacer" do
    t = Transaction.new 
    t.transaction_type = "sale"
    t.prepare(@member, @credit_card, 34.56, @member.terms_of_membership.payment_gateway_configuration)
    answer = t.process
    unless t.success?
      Auditory.audit!(self, answer)
    end
    assert true
  end
end
