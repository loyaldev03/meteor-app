require 'test_helper'

class Api::ClubCashTransactionControllerTest < ActionController::TestCase
  setup do
    @admin_user           = FactoryBot.create(:confirmed_admin_agent)
    @api_user             = FactoryBot.create(:confirmed_api_agent)
    @representative_user  = FactoryBot.create(:confirmed_representative_agent)
    @supervisor_user      = FactoryBot.create(:confirmed_supervisor_agent)
    @agency_user          = FactoryBot.create(:confirmed_agency_agent)
    @landing_user         = FactoryBot.create(:confirmed_landing_agent)
    @club                 = FactoryBot.create(:club_with_api)
    @partner              = @club.partner
    Time.zone             = @club.time_zone
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @wordpress_terms_of_membership    = FactoryBot.create :wordpress_terms_of_membership_with_gateway, club_id: @club.id
    Drupal.enable_integration!
    Drupal.test_mode!
    Drupal::UserPoints.any_instance.stubs(:create!).returns('true')
  end

  test 'admin should not add club cash transaction if domain is drupal' do
    sign_in @admin_user
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, created_by: @admin_agent)
    assert_difference('ClubCashTransaction.count', 0) do
      post(:create,  member_id: @saved_user.id,
                              club_cash_transaction: {
                                amount: 100,
                                description: 'adding club cash'
                              }, format: :json)
    end
    assert_response :success
  end

  test 'admin should add club cash transaction' do
    sign_in @admin_user
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)
    @club.update_attribute :api_type, ''

    assert_difference('ClubCashTransaction.count') do
      post(:create,  member_id: @saved_user.id,
                              club_cash_transaction: {
                                amount: 100,
                                description: 'adding club cash'
                              }, format: :json)
    end
    assert_response :success
  end

  test 'representative should not add club cash transaction' do
    sign_in @representative_user
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)

    assert_difference('ClubCashTransaction.count', 0) do
      post(:create, member_id: @saved_user.id,
                    club_cash_transaction: {
                      amount: 100,
                      description: 'adding club cash'
                    }, format: :json)
    end
    assert_response :unauthorized
  end

  test 'supervisor should add club cash transaction' do
    sign_in @supervisor_user
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)
    @club.update_attribute :api_type, ''

    assert_difference('ClubCashTransaction.count') do
      post(:create,  member_id: @saved_user.id,
                     club_cash_transaction: {
                       amount: 100,
                       description: 'adding club cash'
                     }, format: :json)
    end
    assert_response :success
  end

  test 'agency should not add club cash transaction' do
    sign_in @agency_user
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)

    assert_difference('ClubCashTransaction.count', 0) do
      post(:create,  member_id: @saved_user.id,
                     club_cash_transaction: {
                       amount: 100,
                       description: 'adding club cash'
                     }, format: :json)
    end
    assert_response :unauthorized
  end

  test 'Should not let add club cash when club does not allow to' do
    sign_in @admin_user
    @club.update_attribute :club_cash_enable, false
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)
    post(:create, member_id: @saved_user.id,
                  club_cash_transaction: {
                    amount: 100,
                    description: 'adding club cash'
                  }, format: :json)
    assert @response.body.include?(I18n.t('error_messages.club_cash_not_supported'))
    assert @response.body.include?(Settings.error_codes.club_does_not_support_club_cash)
  end

  test 'landing should not add club cash transaction' do
    sign_in @landing_user
    @saved_user = create_active_user(@wordpress_terms_of_membership, :active_user, nil, {}, created_by: @admin_agent)

    assert_difference('ClubCashTransaction.count', 0) do
      post(:create,  member_id: @saved_user.id,
                              club_cash_transaction: {
                                amount: 100,
                                description: 'adding club cash'
                              }, format: :json)
    end
    assert_response :unauthorized
  end
end
