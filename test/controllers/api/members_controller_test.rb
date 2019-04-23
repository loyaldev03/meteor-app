require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user                       = FactoryBot.create(:confirmed_admin_agent)
    @representative_user              = FactoryBot.create(:confirmed_representative_agent)
    @fulfillment_manager_user         = FactoryBot.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user                  = FactoryBot.create(:confirmed_supervisor_agent)
    @api_user                         = FactoryBot.create(:confirmed_api_agent)
    @agency_agent                     = FactoryBot.create(:confirmed_agency_agent)
    @fulfillment_managment_user       = FactoryBot.create(:confirmed_fulfillment_manager_agent)
    @club                             = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
    @club_with_api                    = FactoryBot.create(:club_with_spree_api)
    @terms_of_membership              = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id
    @terms_of_membership_with_api     = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club_with_api.id)
    @preferences                      = { 'color' => 'green', 'car' => 'dodge' }
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @credit_card      = FactoryBot.build :credit_card
    @membership_info  = FactoryBot.build :membership_with_enrollment_info
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @credit_card.number)
    # active_merchant_stubs_payeezy
  end

  def generate_put_message(options = {}, setter_options = {})
    put(:update,  id: @user.id, member: { first_name: @user.first_name,
                                          last_name: @user.last_name,
                                          address: @user.address,
                                          gender: 'M',
                                          city: @user.city,
                                          zip: @user.zip,
                                          state: @user.state,
                                          email: @user.email,
                                          country: @user.country,
                                          type_of_phone_number: @user.type_of_phone_number,
                                          phone_country_code: @user.phone_country_code,
                                          phone_area_code: @user.phone_area_code,
                                          phone_local_number: @user.phone_local_number,
                                          birth_date: @user.birth_date,
                                          credit_card: { number: @credit_card.number,
                                                         expire_month: @credit_card.expire_month,
                                                         expire_year: @credit_card.expire_year } }.merge(options), setter: {}.merge(setter_options), format: :json)
  end

  def generate_post_message(options = {}, options2 = {})
    post(:create, { member: { first_name: @user.first_name,
                              last_name: @user.last_name,
                              address: @user.address,
                              gender: 'M',
                              city: @user.city,
                              zip: @user.zip,
                              state: @user.state,
                              email: @user.email,
                              country: @user.country,
                              type_of_phone_number: @user.type_of_phone_number,
                              phone_country_code: @user.phone_country_code,
                              phone_area_code: @user.phone_area_code,
                              phone_local_number: @user.phone_local_number,
                              enrollment_amount: @membership_info.enrollment_amount,
                              terms_of_membership_id: @terms_of_membership.id,
                              birth_date: @user.birth_date,
                              preferences: @preferences,
                              credit_card: { number: @credit_card.number,
                                             expire_month: @credit_card.expire_month,
                                             expire_year: @credit_card.expire_year },
                              product_sku: @membership_info.product_sku,
                              product_description: @membership_info.product_description,
                              utm_campaign: @membership_info.utm_campaign,
                              audience: @membership_info.audience,
                              campaign_id: @membership_info.campaign_code,
                              ip_address: @membership_info.ip_address }.merge(options), format: :json }.merge(options2))
  end

  def generate_put_next_bill_date(next_bill_date)
    put(:next_bill_date, id: @user.id, next_bill_date: next_bill_date)
  end

  def generate_put_cancel(cancel_date, reason)
    put(:cancel, id: @user.id, cancel_date: cancel_date, reason: reason)
  end

  def generate_get_by_updated(club_id, start_date, end_date)
    get(:find_all_by_updated, club_id: club_id, start_date: start_date, end_date: end_date)
  end

  def generate_get_by_created(club_id, start_date, end_date)
    get(:find_all_by_created, club_id: club_id, start_date: start_date, end_date: end_date)
  end

  def generate_post_sale(amount, description, type)
    post(:sale, id: @user.id, amount: amount, description: description, type: type)
  end

  def generate_post_get_banner_by_email(email)
    post(:get_banner_by_email, email: email)
  end

  def generate_post_update_terms_of_membership(user_id, terms_of_membership_id, credit_card = {}, prorated = true)
    post(:update_terms_of_membership, id_or_email: user_id,
                                      terms_of_membership_id: terms_of_membership_id,
                                      credit_card: credit_card,
                                      prorated: prorated,
                                      format: :json)
  end

  def get_show(user_id)
    post(:show, id: user_id, format: :json)
  end

  def generate_put_club_cash(user_id, amount, expire_date = nil)
    data = { id: user_id, amount: amount, format: :json }
    data[:expire_date] = expire_date if expire_date
    put(:club_cash, data)
  end

  def active_merchant_stub
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, @credit_card.number)
  end

  ################################################################
  ######## create
  ################################################################

  test 'Allow enroll/create users.' do
    %i[confirmed_admin_agent confirmed_api_agent confirmed_supervisor_agent
       confirmed_representative_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @current_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
        @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id
        @user                 = FactoryBot.build :user_with_api
        generate_post_message
        assert_response :success
        saved_user = User.find_by(email: @user.email)
        assert_equal(saved_user.club_cash_amount, @terms_of_membership.initial_club_cash_amount)
        assert_not_nil saved_user.transactions.find_by(operation_type: 100, amount: @membership_info.enrollment_amount)
      end
    end
  end

  test 'Admin should enroll/create user within club related to external API' do
    sign_in @admin_user
    @club = @club_with_api
    Drupal.enable_integration!
    Drupal.test_mode!
    @user                 = FactoryBot.build :user_with_api
    @current_club         = @terms_of_membership.club
    @current_agent        = @admin_user
    active_merchant_stub
    generate_post_message

    assert_response :success
    user_created  = User.find_by(email: @user.email)
    response      = JSON.parse(@response.body)
    assert_equal response['bill_date'], user_created.next_retry_bill_date.strftime('%m/%d/%Y')
    assert_equal response['api_role'], [user_created.terms_of_membership.api_role]
  end

  test 'Do not allow create user to agency or landing agents' do
    %i[confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @user             = FactoryBot.build :user_with_api
        @current_club     = @terms_of_membership.club
        @current_agent    = @agency_agent
        active_merchant_stub
        assert_difference('User.count', 0) do
          generate_post_message
          assert_response :unauthorized
        end
      end
    end
  end

  test 'When no param is provided on creation, it should tell us so' do
    sign_in @admin_user
    assert_difference('Membership.count', 0) do
      assert_difference('Transaction.count', 0) do
        assert_difference('User.count', 0) do
          post :create
          assert_response :success
        end
      end
    end
    response = JSON.parse @response.body
    assert_equal response['code'], Settings.error_codes.wrong_data
    assert_equal response['message'], 'There are some params missing. Please check them.'
  end

  test 'Does not allow enroll/create users within club where agent does not have access.' do
    %i[admin api supervisor representative fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        @another_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
        @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
        @user                 = FactoryBot.build :user_with_api
        generate_post_message
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## update
  ################################################################

  test 'Allow update users.' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent confirmed_representative_agent
       confirmed_supervisor_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @credit_card.number = "XXXX-XXXX-XXXX-#{@user.active_credit_card.last_digits}"

        assert_difference('Operation.count') do
          generate_put_message
          assert_not_nil @user.operations.find_by(operation_type: Settings.operation_types.profile_updated)
          assert_response :success
        end
      end
    end
  end

  test 'api_id should be updated if batch_update enabled' do
    sign_in @admin_user
    @user               = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    @credit_card        = FactoryBot.create :credit_card_master_card, active: false
    @credit_card.number = "XXXX-XXXX-XXXX-#{@user.active_credit_card.last_digits}"
    new_api_id          = @user.api_id.to_i + 10
    active_merchant_stub

    generate_put_message
    assert_response :success
    assert_nil @user.reload.api_id

    generate_put_message({ first_name: 'testing2', api_id: new_api_id }, batch_update: false)
    assert_response :success
    assert_nil @user.reload.api_id

    generate_put_message({ api_id: new_api_id }, batch_update: true)
    assert_response :success
    assert_equal new_api_id.to_s, @user.reload.api_id.to_s
  end

  test 'Do not allow update user to agency or landing agents' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          generate_put_message
          assert_response :unauthorized
          assert_nil @user.operations.find_by(operation_type: Settings.operation_types.profile_updated)
        end
      end
    end
  end

  test 'When no param is provided on update, it should tell us so' do
    sign_in @admin_user
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_difference('Membership.count', 0) do
      assert_difference('Transaction.count', 0) do
        assert_difference('User.count', 0) do
          put(:update, id: @user.id)
          assert_response :success
        end
      end
    end
    response = JSON.parse @response.body
    assert_equal response['code'], Settings.error_codes.wrong_data
    assert_equal response['message'], 'There are some params missing. Please check them.'
  end

  test 'Does not allow update users within club where agent does not have access.' do
    @another_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
    @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
    @user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[admin api supervisor representative fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          generate_put_message
          assert_response :unauthorized
          assert_nil @user.operations.find_by(operation_type: Settings.operation_types.profile_updated)
        end
      end
    end
  end

  ################################################################
  ######## club_cash
  ################################################################

  test 'Allows to update club_cash' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_api)
    %i[confirmed_admin_agent confirmed_api_agent confirmed_supervisor_agent
       confirmed_representative_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        sign_in @admin_user
        new_amount, new_expire_date = 34, Date.today
        old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
        put(:club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date, :format => :json })
        response = JSON.parse(@response.body)
        assert_response :success
        assert_equal response['code'], Settings.error_codes.success
        assert_equal @user.reload.club_cash_amount, new_amount
      end
    end
  end

  test 'Do not allow update club_cash to agency or landing agents' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          new_amount, new_expire_date = 34, Date.today
          old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
          put(:club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date, :format => :json })
          assert_response :unauthorized
        end
      end
    end
  end

  test 'Admin is not able to update club cash amount on Club without api' do
    sign_in @admin_user
    @user                       = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
    put(:club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date, format: :json })
    response = JSON.parse(@response.body)
    assert_response :success
    assert_equal response['code'], Settings.error_codes.club_cash_cant_be_fixed
    assert_equal response['message'], 'This club is not allowed to fix the amount of the club cash on members.'
    assert_equal @user.reload.club_cash_amount, old_amount
  end

  test 'Admin is not able to update club cash amount on Club where club cash is not enabled' do
    sign_in @admin_user
    @club_with_api.update_attribute :club_cash_enable, false
    @user                       = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_api.reload)
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
    put(:club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date, format: :json })
    response = JSON.parse(@response.body)
    assert_response :success
    assert_equal response['code'], Settings.error_codes.club_does_not_support_club_cash
    assert_equal response['message'], I18n.t('error_messages.club_cash_not_supported')
    assert_equal @user.reload.club_cash_amount, old_amount
  end

  test 'Admin is not able to update club cash amount on Club where billing is not enabled' do
    sign_in @admin_user
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_api)
    @club_with_api.update_attribute :billing_enable, false
    @user.reload
    new_amount, new_expire_date = 34, Date.today
    old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
    put(:club_cash, { id: @user.id, amount: new_amount, expire_date: new_expire_date, format: :json })
    response = JSON.parse(@response.body)
    assert_response :success
    assert_equal response['code'], Settings.error_codes.club_does_not_support_club_cash
    assert_equal response['message'], I18n.t('error_messages.club_cash_not_supported')
    assert_equal @user.reload.club_cash_amount, old_amount
  end

  test 'Admin is not able to update negative club cash amount' do
    sign_in @admin_user
    @user         = enroll_user(FactoryBot.build(:user), @terms_of_membership.reload)
    old_club_cash = @user.club_cash_amount
    generate_put_club_cash(@user.id, -1000)
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal response['code'], Settings.error_codes.wrong_data
    assert_equal response['message'], I18n.t('error_messages.club_cash.negative_amount')
    assert_equal old_club_cash, @user.reload.club_cash_amount
  end

  test 'Admin is not able to update club cash amount without passing amount' do
    sign_in @admin_user
    @user         = enroll_user(FactoryBot.build(:user), @terms_of_membership.reload)
    old_club_cash = @user.club_cash_amount
    generate_put_club_cash(@user.id, '')
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal response['code'], Settings.error_codes.wrong_data
    assert_equal response['message'], I18n.t('error_messages.club_cash.null_amount')
    assert_equal old_club_cash, @user.reload.club_cash_amount
  end

  test 'Does not allow to update club_cash on users from other club.' do
    @another_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
    @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
    @user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[admin api supervisor representative fulfillment_managment].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        new_amount, new_expire_date = 34, Date.today
        old_amount, old_expire_date = @user.club_cash_amount, @user.club_cash_expire_date
        assert_difference('Operation.count', 0) do
          put(:club_cash, id: @user.id, amount: new_amount, expire_date: new_expire_date, :format => :json)
          assert_response :unauthorized
        end
      end
    end
  end

  ################################################################
  ######## next_bill_date
  ################################################################

  test 'Allows to update next_bill_date' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        next_bill_date = I18n.l(@user.next_retry_bill_date + 3.day, format: :dashed)
        assert_difference('Operation.count') do
          generate_put_next_bill_date(next_bill_date)
          assert_response :success
          response = JSON.parse(@response.body)
          assert_equal response['code'], Settings.error_codes.success
          assert response['message'].include? "Next bill date changed to #{next_bill_date.to_date} "
        end
      end
    end
  end

  test 'Admin and Api gets error when trying to update next_bill_date and not passing user_id' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        FactoryBot.create :credit_card, user_id: @user.id

        next_bill_date = I18n.l(Time.zone.now + 3.day, format: :dashed)
        assert_difference('Operation.count', 0) do
          put(:next_bill_date, id: '', next_bill_date: next_bill_date)
          assert_response :success
          response = JSON.parse(@response.body)
          assert_equal response['code'], Settings.error_codes.not_found
          assert response['message'].include? 'Member not found'
        end
      end
    end
  end

  test 'non Admin/API should not updates next_bill_date' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_agency_agent
       confirmed_fulfillment_manager_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          generate_put_next_bill_date(I18n.l(Time.zone.now + 3.days, format: :only_date))
          assert_response :unauthorized
        end
      end
    end
  end

  test 'Does not allow update next_bill_date on users from other club.' do
    @another_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
    @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @another_club.id
    @user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[admin api].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          generate_put_next_bill_date(I18n.l(Time.zone.now + 3.days, format: :only_date))
          assert_response :unauthorized
        end
      end
    end
  end

  ################################################################
  ######## find_all_by_updated
  ################################################################

  test 'get users updated between given dates' do
    3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }
    first = User.first
    last  = User.last
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        first.update_attribute :updated_at, Time.zone.now - 10.days
        last.update_attribute :updated_at, Time.zone.now - 8.days
        generate_get_by_updated first.club_id, Time.zone.now - 11.day, Time.zone.now - 9.day
        assert @response.body.include? first.id.to_s
        assert !(@response.body.include? last.id.to_s)
      end
    end
  end

  test 'get users updated between given dates with start date greater to end' do
    sign_in @admin_user
    generate_get_by_updated 5, Time.zone.now - 9.day, Time.zone.now - 11.day
    assert @response.body.include? 'Check both start and end date, please. Start date is greater than end date'
  end

  test 'get users updated between given dates with blank date' do
    sign_in @admin_user
    3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }
    generate_get_by_updated 5, '', Time.zone.now - 10.day
    assert @response.body.include? 'Make sure to send both start and end dates, please. There seems to be at least one as null or blank'
    generate_get_by_updated 5, Time.zone.now - 10.day, ''
    assert @response.body.include? 'Make sure to send both start and end dates, please. There seems to be at least one as null or blank'
  end

  test 'get users updated between given dates with wrong format date' do
    sign_in @admin_user
    3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }

    generate_get_by_updated 5, '1234567', Time.zone.now - 10.day
    assert @response.body.include? 'Check both start and end date format, please. It seams one of them is in an invalid format'
    generate_get_by_updated 5, Time.zone.now - 10.day, '1234567'
    assert @response.body.include? 'Check both start and end date format, please. It seams one of them is in an invalid format'
  end

  test 'Representative should not get users updated between given dates' do
    sign_in @representative_user
    generate_get_by_updated 5, Time.zone.now - 11.day, Time.zone.now - 9.day
    assert_response :unauthorized
  end

  test 'Supervisor should not get users updated between given dates' do
    sign_in @supervisor_user
    generate_get_by_updated 5, Time.zone.now - 11.day, Time.zone.now - 9.day
    assert_response :unauthorized
  end

  test 'Agency should not get users updated between given dates' do
    sign_in @agency_agent
    generate_get_by_updated 5, Time.zone.now - 11.day, Time.zone.now - 9.day
    assert_response :unauthorized
  end

  test 'Fulfillment manager should not get users updated between given dates' do
    sign_in @fulfillment_managment_user
    generate_get_by_updated 5, Time.zone.now - 11.day, Time.zone.now - 9.day
    assert_response :unauthorized
  end

  test 'Api should not get users updated between given dates' do
    sign_in @api_user
    3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }
    first = User.first
    last = User.last
    first.update_attribute :updated_at, Time.zone.now - 10.days
    last.update_attribute :updated_at, Time.zone.now - 8.days

    generate_get_by_updated first.club_id, Time.zone.now - 11.day, Time.zone.now - 9.day
    assert @response.body.include? first.id.to_s
    assert !(@response.body.include? last.id.to_s)
  end

  ################################################################
  ######## find_all_by_created
  ################################################################

  test 'get users created between given dates' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }
        first = User.first
        last = User.last
        first.update_attribute :created_at, Time.zone.now - 10.days
        last.update_attribute :created_at, Time.zone.now - 8.days

        generate_get_by_created first.club_id, Time.zone.now - 11.day, Time.zone.now - 9.day
        assert @response.body.include? first.id.to_s
        assert !(@response.body.include? last.id.to_s)
      end
    end
  end

  test 'get users created between given dates with blank date' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }

        generate_get_by_created 5, '', Time.zone.now - 10.day
        assert @response.body.include? 'Make sure to send both start and end dates, please. There seems to be at least one as null or blank'
        generate_get_by_created 5, Time.zone.now - 10.day, ''
        assert @response.body.include? 'Make sure to send both start and end dates, please. There seems to be at least one as null or blank'
      end
    end
  end

  test 'get users created between given dates with wrong format date' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        3.times { enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true) }

        generate_get_by_created 5, '1234567', Time.zone.now - 10.day
        assert @response.body.include? 'Check both start and end date format, please. It seams one of them is in an invalid format'
        generate_get_by_created 5, Time.zone.now - 10.day, '1234567'
        assert @response.body.include? 'Check both start and end date format, please. It seams one of them is in an invalid format'
      end
    end
  end

  test 'Non Admin nor api agents should not get users created between given dates' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_fulfillment_manager_agent confirmed_agency_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        generate_get_by_created 5, Time.zone.now - 11.day, Time.zone.now - 9.day
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## cancel
  ################################################################

  test 'Admin, Api and FulfillmentManagers agents can cancel user' do
    %i[confirmed_admin_agent confirmed_api_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @current_club         = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
        @terms_of_membership  = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id
        @user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)

        cancel_date = I18n.l(Time.zone.now + 2.days, format: :only_date)
        assert_difference('Operation.count') do
          generate_put_cancel(cancel_date, 'Reason')
          assert_response :success
        end
        @user.reload
        cancel_date_to_check = cancel_date
        cancel_date_to_check = cancel_date_to_check.to_datetime.change(offset: @user.get_offset_related)
        assert @user.current_membership.cancel_date > @user.current_membership.join_date
        assert_equal I18n.l(@user.current_membership.cancel_date.utc, format: :only_date), I18n.l(cancel_date_to_check.utc, :format => :only_date)
      end
    end
  end

  test 'Should not cancel user when cancel date is in wrong format' do
    sign_in @admin_user
    @membership = FactoryBot.create(:user_with_api_membership)
    @user       = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    @user.update_attribute :current_membership_id, @membership.id
    FactoryBot.create :credit_card, user_id: @user.id
    cancel_date = I18n.l(Time.zone.now + 2.days, format: :only_date)

    assert_difference('Operation.count', 0) do
      generate_put_cancel(cancel_date, '')
      assert_response :success
    end
    assert @response.body.include?('Reason missing. Please, make sure to provide a reason for this cancelation.')
  end

  test 'Non Admin, Api nor FulfillmentManager agents can cancel memeber' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_agency_agent confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Operation.count', 0) do
          generate_put_cancel(I18n.l(Time.zone.now + 2.days, format: :only_date), 'Reason')
          assert_response :unauthorized, "Agent #{agent} can cancel users"
        end
      end
    end
  end

  ################################################################
  ######## change_terms_of_membership
  ################################################################

  test 'Admin and API agents can change TOM throught API' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        %i[active_user provisional_user].each do |user_type|
          @current_club               = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
          @terms_of_membership        = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id
          @terms_of_membership_second = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id, name: 'secondTom'
          @saved_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
          @saved_user.set_as_active! if user_type == :active_user

          post(:change_terms_of_membership, id: @saved_user.id, terms_of_membership_id: @terms_of_membership_second.id, format: :json)
          assert_response :success
          assert_equal @saved_user.reload.current_membership.terms_of_membership_id, @terms_of_membership_second.id
          assert_not_nil @saved_user.operations.find_by(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})", operation_type: Settings.operation_types.save_the_sale_through_api)
        end
      end
    end
  end

  test 'non Admin nor Api agents can not change TOM throught API' do
    @terms_of_membership_second = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id, name: 'secondTom'
    @saved_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_fulfillment_manager_agent
       confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        post(:change_terms_of_membership, id: @saved_user.id, terms_of_membership_id: @terms_of_membership_second.id, format: :json)
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## update_terms_of_membership
  ################################################################

  test 'All agents can update_terms_of_membership providing id' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @current_club               = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
        @terms_of_membership        = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id
        @terms_of_membership_second = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id, name: 'secondTom'
        @saved_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)

        post(:update_terms_of_membership, id_or_email: @saved_user.id, terms_of_membership_id: @terms_of_membership_second.id, prorated: 0, format: :json)
        assert_response :success
        @saved_user.reload
        assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
        assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.update_terms_of_membership
      end
    end
  end

  test 'All agents can update_terms_of_membership providing email' do
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @current_club               = FactoryBot.create(:simple_club_with_gateway, family_memberships_allowed: false)
        @terms_of_membership        = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id
        @terms_of_membership_second = FactoryBot.create :terms_of_membership_with_gateway, club_id: @current_club.id, name: 'secondTom'
        @saved_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)

        post(:update_terms_of_membership, id_or_email: @saved_user.email, terms_of_membership_id: @terms_of_membership_second.id, prorated: 0, format: :json)
        assert_response :success
        @saved_user.reload
        assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_second.id
        assert_equal @saved_user.operations.where(description: "Change of TOM from API from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.update_terms_of_membership
      end
    end
  end

  test 'Non admin nor api agent can not update_terms_of_membership' do
    @saved_user                 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    @terms_of_membership_second = FactoryBot.create :terms_of_membership_with_gateway, club_id: @club.id, name: 'secondTom'
    %i[confirmed_fulfillment_manager_agent confirmed_supervisor_agent confirmed_representative_agent
       confirmed_landing_agent confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        post(:update_terms_of_membership, id_or_email: @saved_user.id, terms_of_membership_id: @terms_of_membership_second.id, prorated: 0, format: :json)
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## sale
  ################################################################

  test 'Admin and Api can one time bill an user.' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        Timecop.travel(@user.next_retry_bill_date) do
          assert_difference('Operation.count') do
            assert_difference('Transaction.count') do
              generate_post_sale(@user.terms_of_membership.installment_amount, 'testing', 'one-time')
              assert_not_nil @user.reload.operations.find_by(operation_type: Settings.operation_types.no_recurrent_billing)
            end
          end
        end
      end
    end
  end

  test 'Admin and Api can one time bill an user (donation).' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        Timecop.travel(@user.next_retry_bill_date) do
          assert_difference('Operation.count') do
            assert_difference('Transaction.count') do
              generate_post_sale(@user.terms_of_membership.installment_amount, 'testing', 'donation')
            end
          end
        end
        assert_not_nil @user.reload.operations.find_by(operation_type: Settings.operation_types.no_reccurent_billing_donation)
      end
    end
  end

  test 'Should not allow sale transaction for agents that are not admin or api.' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_landing_agent
       confirmed_agency_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        FactoryBot.create :credit_card, user_id: @user.id
        @user.set_as_provisional
        generate_post_sale(@user.terms_of_membership.installment_amount, 'testing', 'one-time')
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## get_banner_by_email
  ################################################################

  test 'Admin and Api agents can get banner by email' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %w[admin api].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        @club.member_banner_url       = 'https://member_banner_url.com'
        @club.non_member_banner_url   = 'https://non_member.banner_url.com'
        @club.member_landing_url      = 'https://member_landing_url.com'
        @club.non_member_landing_url  = 'https://non_member_landing_url.com'
        @club.save(validate: false)
        generate_post_get_banner_by_email('')
        assert_response :success
        assert @response.body.include? @club.non_member_banner_url
        assert @response.body.include? @club.non_member_landing_url
        generate_post_get_banner_by_email('wrongFormat')
        assert_response :success
        assert @response.body.include? @club.non_member_banner_url
        assert @response.body.include? @club.non_member_landing_url
        generate_post_get_banner_by_email('does@notexist.com')
        assert_response :success
        assert @response.body.include? @club.non_member_banner_url
        assert @response.body.include? @club.non_member_landing_url
        generate_post_get_banner_by_email(@user.email)
        assert_response :success
        assert @response.body.include? @club.member_banner_url
        assert @response.body.include? @club.member_landing_url
      end
    end
  end

  test 'Should not allow get banner by email for agents that are not admin or api.' do
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %w[supervisor representative agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        generate_post_get_banner_by_email(@user.email)
        assert_response :unauthorized
      end
    end
  end

  ################################################################
  ######## show
  ################################################################

  test 'Admin should get user information' do
    saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_admin_agent confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get_show(saved_user.id)
        assert_response :success
      end
    end
  end

  test 'Should not allow show information for agents that are not admin or api.' do
    saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    %i[confirmed_supervisor_agent confirmed_representative_agent confirmed_landing_agent
      confirmed_agency_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get_show(saved_user.id)
        assert_response :unauthorized
      end
    end
  end
end
