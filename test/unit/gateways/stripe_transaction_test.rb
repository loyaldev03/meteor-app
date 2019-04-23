class StripeTransactionTest < ActiveSupport::TestCase
  def setup
    active_merchant_stubs_stripe
    @current_agent        = FactoryBot.create(:agent)
    @club                 = FactoryBot.create(:simple_club_with_stripe_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @credit_card          = FactoryBot.build(:credit_card_visa_stripe)
    @user                 = FactoryBot.build(:user)
  end

  test 'Enroll with Stripe' do
    assert_difference('Transaction.count', 1) do
      enroll_user(@user, @terms_of_membership, 23, false, @credit_card)
    end
  end

  test 'Bill membership with Stripe' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
    end
  end

  test 'Full refund with Stripe' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount      = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      trans   = active_user.transactions.last
      answer  = Transaction.refund(amount, trans.id)
      assert_equal answer[:code], '000', answer[:message]
    end
    assert_equal Transaction.find_by_transaction_type('refund').operation_type, Settings.operation_types.credit
  end

  test 'Partial refund with Stripe' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount      = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      sale_transaction  = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount   = amount / 2
      answer            = Transaction.refund(refunded_amount, sale_transaction.id)
      assert_equal answer[:code], '000', answer[:message]
      assert_equal Transaction.where("user_id = ? and operation_type = ? and transaction_type = 'refund'", active_user.id, Settings.operation_types.credit).count, 1
    end
  end
end
