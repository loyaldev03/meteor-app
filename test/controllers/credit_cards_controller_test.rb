require 'test_helper'

class CreditCardsControllerTest < ActionController::TestCase
  setup do
    @admin_user           = FactoryBot.create(:confirmed_admin_agent)
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
    @partner              = @club.partner
    @saved_user           = enroll_user(FactoryBot.build(:user), @terms_of_membership)
  end

  def generate_post(club, saved_user, credit_card)
    post :create, partner_prefix: club.partner.prefix,
                  club_prefix: club.name,
                  user_prefix: saved_user.id,
                  credit_card: { number: credit_card.number, expire_month: credit_card.expire_month, expire_year: credit_card.expire_year }
  end

  def generate_delete(club, saved_user, credit_card)
    delete :destroy, partner_prefix: club.partner.prefix,
                     club_prefix: club.name,
                     user_prefix: saved_user.id,
                     id: credit_card.id
  end

  test 'Agents that can create credit card' do
    %i[confirmed_admin_agent confirmed_supervisor_agent confirmed_representative_agent
       confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        club                  = FactoryBot.create(:simple_club_with_gateway)
        terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: club.id
        saved_user           = enroll_user(FactoryBot.build(:user), terms_of_membership)
        credit_card          = FactoryBot.build :credit_card_american_express

        assert_difference('Operation.count', 2) do
          assert_difference('CreditCard.count', 1) do
            active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
            generate_post(club, saved_user, credit_card)
            assert_response :redirect
            assert_nil saved_user.active_credit_card.number
            assert_equal(saved_user.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number])
            assert_equal(saved_user.active_credit_card.expire_month, credit_card.expire_month)
          end
        end
      end
    end
  end

  test 'Agents that can not create credit card' do
    %i[confirmed_api_agent confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        club                  = FactoryBot.create(:simple_club_with_gateway)
        terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: club.id
        original_credit_card  = FactoryBot.build(:credit_card)
        saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership, 23, false, original_credit_card)
        credit_card           = FactoryBot.build :credit_card_american_express

        assert_difference('Operation.count', 0) do
          assert_difference('CreditCard.count', 0) do
            active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
            generate_post(club, saved_user, credit_card)
            assert_response :unauthorized
            assert_nil saved_user.active_credit_card.number
            assert_equal(saved_user.active_credit_card.token, CREDIT_CARD_TOKEN[original_credit_card.number])
          end
        end
      end
    end
  end

  test 'Agents that can delete credit card' do
    %i[confirmed_admin_agent confirmed_supervisor_agent confirmed_representative_agent
       confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        club                  = FactoryBot.create(:simple_club_with_gateway)
        terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: club.id
        saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership)
        second_credit_card    = FactoryBot.create(:credit_card_american_express, user_id: saved_user.id, active: false)

        assert_difference('Operation.count') do
          assert_difference('CreditCard.count', -1) do
            generate_delete(club, saved_user, second_credit_card)
            assert_response :redirect
          end
        end
      end
    end
  end

  test 'Agents that can not delete credit card' do
    %i[confirmed_api_agent confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        club                  = FactoryBot.create(:simple_club_with_gateway)
        terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: club.id
        saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership)
        second_credit_card    = FactoryBot.create(:credit_card_american_express, user_id: saved_user.id, active: false)

        assert_difference('Operation.count', 0) do
          assert_difference('CreditCard.count', 0) do
            generate_delete(club, saved_user, second_credit_card)
            assert_response :unauthorized
          end
        end
      end
    end
  end

  ####################################################
  # #CLUBS ROLES
  ####################################################

  test 'Agents that can create credit card based on club roles' do
    %w[admin supervisor representative fulfillment_managment].each do |role|
      @club               = FactoryBot.create(:simple_club_with_gateway)
      terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
      saved_user          = enroll_user(FactoryBot.build(:user), terms_of_membership)
      credit_card         = FactoryBot.build :credit_card_american_express
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 2) do
          assert_difference('CreditCard.count', 1) do
            active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
            generate_post(@club, saved_user, credit_card)
            assert_response :redirect
            assert_nil saved_user.active_credit_card.number
            assert_equal(saved_user.active_credit_card.token, CREDIT_CARD_TOKEN[credit_card.number])
            assert_equal(saved_user.active_credit_card.expire_month, credit_card.expire_month)
          end
        end
      end
    end
  end

  test 'Agents that can not create credit card based on club roles' do
    %w[api landing agency].each do |role|
      @club                 = FactoryBot.create(:simple_club_with_gateway)
      terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
      original_credit_card  = FactoryBot.build(:credit_card)
      saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership)
      credit_card           = FactoryBot.build :credit_card_american_express
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          assert_difference('CreditCard.count', 0) do
            active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
            generate_post(@club, saved_user, credit_card)
            assert_response :unauthorized
            assert_nil saved_user.active_credit_card.number
            assert_equal(saved_user.active_credit_card.token, CREDIT_CARD_TOKEN[original_credit_card.number])
          end
        end
      end
    end
  end

  test 'Agents that can delete credit card based on club role' do
    %w[admin supervisor representative fulfillment_managment].each do |role|
      @club                 = FactoryBot.create(:simple_club_with_gateway)
      terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
      saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership)
      second_credit_card    = FactoryBot.create(:credit_card_american_express, user_id: saved_user.id, active: false)
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count') do
          assert_difference('CreditCard.count', -1) do
            generate_delete(@club, saved_user, second_credit_card)
            assert_response :redirect
          end
        end
      end
    end
  end

  test 'Agents that can not delete credit card based on club role' do
    %w[api landing agency].each do |role|
      @club                 = FactoryBot.create(:simple_club_with_gateway)
      terms_of_membership   = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
      saved_user            = enroll_user(FactoryBot.build(:user), terms_of_membership)
      second_credit_card    = FactoryBot.create(:credit_card_american_express, user_id: saved_user.id, active: false)
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          assert_difference('CreditCard.count', 0) do
            generate_delete(@club, saved_user, second_credit_card)
            assert_response :unauthorized
          end
        end
      end
    end
  end
end
