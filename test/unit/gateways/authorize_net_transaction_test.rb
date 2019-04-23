class AuthorizeNetTransactionTest < ActiveSupport::TestCase
  def setup
    active_merchant_stubs_auth_net
    @current_agent                = FactoryBot.create(:agent)
    @club                         = FactoryBot.create(:simple_club_with_authorize_net_gateway)
    @terms_of_membership          = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @sd_strategy                  = FactoryBot.create(:soft_decline_strategy)
    @sd_auth_net_expired_strategy = FactoryBot.create(:soft_decline_strategy, response_code: '316', gateway: 'authorize_net')
    @user                         = FactoryBot.build(:user)
    @credit_card                  = FactoryBot.build(:credit_card_american_express_authorize_net)
  end

  test 'Bill membership with Authorize net' do
    active_user = enroll_user(@user, @terms_of_membership, 100, false, @credit_card)
    @terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
    end
  end

  test 'Enroll with Authorize net' do
    assert_difference('Transaction.count', 1) do
      enroll_user(@user, @terms_of_membership, 23, false, @credit_card)
    end
  end

  test 'Try billing a membership when he was previously SD for credit_card_expired for Auth.net' do
    @credit_card  = FactoryBot.build(:credit_card_american_express_authorize_net, token: 'tzNduuh2DRQT7FXUILDl3Q==')
    active_user   = create_active_user(@terms_of_membership)
    active_merchant_stubs_auth_net(@sd_auth_net_expired_strategy.response_code, 'decline stubbed', false)
    active_user.active_credit_card.update_attribute :token, @credit_card.token

    active_user.bill_membership
    Timecop.travel(active_user.next_retry_bill_date) do
      active_merchant_stubs_auth_net
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year + 2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test 'Try billing a membership when he was previously SD for credit_card_expired on different membership for Auth.net' do
    @terms_of_membership_second       = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'second_one')
    active_user                       = enroll_user(@user, @terms_of_membership, 0, false, @credit_card)
    active_user.next_retry_bill_date  = Time.zone.now

    active_merchant_stubs_auth_net(@sd_auth_net_expired_strategy.response_code, 'decline stubbed', false)
    active_user.bill_membership
    active_user.change_terms_of_membership(@terms_of_membership_second.id, 'changing tom', 100)

    Timecop.travel(active_user.next_retry_bill_date) do
      active_merchant_stubs_auth_net
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
