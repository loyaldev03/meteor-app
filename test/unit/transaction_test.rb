require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.create(:agent)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership)
    @member = FactoryGirl.build(:member)
    @member.terms_of_membership = @terms_of_membership
    @credit_card = FactoryGirl.build(:credit_card)
  end

  test "save operation" do
    assert_difference('Operation.count') do
      Auditory.audit(@current_agent, @member, "test")
    end
  end

  test "enrollment" do
    assert_difference('Operation.count') do
      @member.enroll(@credit_card, 23)
    end
    assert_equal @member.status, 'provisional'
  end

  test "controlled refund (refund completely a transaction)" do
    amount = 23
    @member.enroll(@credit_card, amount)
    assert_equal @member.status, 'provisional'
    answer = @member.bill_membership
    assert_equal @member.status, 'paid'
    Transaction.refund(amount, @member.transactions.last)
  end
end
