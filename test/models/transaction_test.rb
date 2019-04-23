require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryBot.create(:agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_gateway_yearly = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card_master_card)
    @sd_strategy = FactoryBot.create(:soft_decline_strategy)
    @sd_mes_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '054')
    @sd_litle_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '305', gateway: 'litle')
    @sd_auth_net_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '316', gateway: 'authorize_net')
    @sd_first_data_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '605', gateway: 'first_data')
    @sd_payeezy_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '522', gateway: 'payeezy')
    @hd_strategy = FactoryBot.create(:hard_decline_strategy, response_code: '502', gateway: 'payeezy')
    FactoryBot.create(:without_grace_period_decline_strategy_monthly, response_code: '9997', gateway: 'payeezy')
    FactoryBot.create(:without_grace_period_decline_strategy_yearly, response_code: '9997', gateway: 'payeezy')
  end

  test 'Calculate gateway_cost on billing membership' do
    active_user   = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount        = @terms_of_membership.installment_amount
    merchant_fee  = FactoryBot.create(:merchant_fee_payeezy)
    gateway_cost  = (amount * (merchant_fee.rate / 100)) + merchant_fee.unit_cost
    assert_difference('Transaction.count') do
      Timecop.travel(active_user.next_retry_bill_date) do
        active_user.bill_membership
        assert_equal active_user.reload.status, 'active'
      end
    end
    assert_equal active_user.transactions.where(transaction_type: 'sale').last.gateway_cost, gateway_cost
  end

  test 'Calculate gateway_cost on enroll' do
    merchant_fee = FactoryBot.create(:merchant_fee_payeezy)
    gateway_cost = (23 * (merchant_fee.rate / 100)) + merchant_fee.unit_cost
    assert_difference('Transaction.count') do
      enroll_user(@user, @terms_of_membership, 23, false, @credit_card)
    end
    assert_equal Transaction.last.gateway_cost, gateway_cost
  end

  test 'Calculate gateway_cost in Full refund' do
    active_user   = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount        = @terms_of_membership.installment_amount
    merchant_fee  = FactoryBot.create(:merchant_fee_payeezy)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      trans = active_user.transactions.last
      Transaction.refund(amount, trans.id)
    end
    assert_equal Transaction.find_by_transaction_type('refund').operation_type, Settings.operation_types.credit
    gateway_cost = (amount * (merchant_fee.rate / 100)) + merchant_fee.unit_cost
    assert_equal Transaction.last.gateway_cost, gateway_cost
  end

  test 'Calculate gateway_cost in Partial refund' do
    active_user   = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount        = @terms_of_membership.installment_amount
    merchant_fee  = FactoryBot.create(:merchant_fee_payeezy)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      sale_transaction  = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount   = amount / 2
      answer            = Transaction.refund(refunded_amount, sale_transaction.id)
      assert_equal answer[:code], '000', answer[:message]
      assert_equal Transaction.where("user_id = ? and operation_type = ? and transaction_type = 'refund'", active_user.id, Settings.operation_types.credit).count, 1
      gateway_cost = (refunded_amount * (merchant_fee.rate / 100)) + merchant_fee.unit_cost
      assert_equal Transaction.last.gateway_cost.to_d.truncate(4).to_f, gateway_cost.to_d.truncate(4).to_f
    end
  end
end
