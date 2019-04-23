require 'test_helper'

class TransactionUnitTest < ActiveSupport::TestCase
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

  test 'Should not refund on sale transactions with different pgc.' do
    active_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    amount      = @terms_of_membership.installment_amount

    Timecop.travel(active_user.next_retry_bill_date) { active_user.bill_membership }

    @club.payment_gateway_configurations.first.delete
    FactoryBot.create(:litle_payment_gateway_configuration, club_id: @club.id)
    assert_equal active_user.reload.status, 'active'

    assert_difference('Operation.count', 0) do
      assert_difference('Transaction.count', 0) do
        assert_difference('Communication.count', 0) do
          trans = active_user.transactions.last
          answer = Transaction.refund(amount, trans.id)
          assert_equal answer[:code], Settings.error_codes.transaction_gateway_differs_from_current
          assert_equal answer[:message], I18n.t('error_messages.transaction_gateway_differs_from_current')
        end
      end
    end
  end
end
