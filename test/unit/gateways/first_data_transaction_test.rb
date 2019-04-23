class FirstDataTransactionTest < ActiveSupport::TestCase
  def setup
    active_merchant_stubs_first_data
    @current_agent        = FactoryBot.create(:agent)
    @club                 = FactoryBot.create(:simple_club_with_first_data_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway_yearly, club_id: @club.id)
    @decline_strategy     = FactoryBot.create(:soft_decline_strategy, response_code: '605', gateway: 'first_data')
    @credit_card          = FactoryBot.build(:credit_card_visa_first_data)
    @user                 = FactoryBot.build(:user)
  end

  test 'Enroll with FirstData' do
    assert_difference('Transaction.count', 1) do
      enroll_user(@user, @terms_of_membership, 23, false, @credit_card)
    end
  end

  test 'Bill membership with FirstData' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.status, 'active'
    end
  end

  test 'Full refund with FirstData' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      trans   = active_user.transactions.last
      answer  = Transaction.refund(amount, trans.id)
      assert_equal answer[:code], '000', answer[:message]
    end
    assert_equal Transaction.find_by_transaction_type('refund').operation_type, Settings.operation_types.credit
  end

  test 'Partial refund with FirstData' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    amount = @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      assert_equal active_user.reload.status, 'active'
      trans           = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount = amount / 2
      answer          = Transaction.refund(refunded_amount, trans.id)
      assert_equal answer[:code], '000', answer[:message]
      assert_equal Transaction.where("user_id = ? and operation_type = ? and transaction_type = 'refund'", active_user.id, Settings.operation_types.credit).count, 1
    end
  end

  test 'Try billing a membership when he was previously SD for credit_card_expired for FirstData' do
    active_user = create_active_user(@terms_of_membership)
    active_merchant_stubs_first_data(@decline_strategy.response_code, 'decline stubbed', false)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
    end

    active_merchant_stubs_first_data
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      assert_equal active_user.active_credit_card.expire_year, old_year + 2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test 'Try billing a membership when he was previously SD for credit_card_expired on different membership for FirstData' do
    @terms_of_membership_second = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'second_one')
    active_user                 = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)

    active_merchant_stubs_first_data(@decline_strategy.response_code, 'decline stubbed', false)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
    end
    active_user.change_terms_of_membership(@terms_of_membership_second.id, 'changing tom', 100)

    active_merchant_stubs_first_data
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year  = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 3) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end
end
