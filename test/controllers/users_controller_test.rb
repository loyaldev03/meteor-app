require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @agent      = FactoryBot.create(:confirmed_admin_agent)
    @partner    = FactoryBot.create(:partner)
    @club       = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @saved_user = FactoryBot.create(:user_with_api, club_id: @club.id, next_retry_bill_date: Time.zone.now + 5.day)
    @saved_user = User.last
    sign_in @agent
  end

  def generate_post_bill_event(amount, description, type)
    post :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name,
                                user_prefix: @saved_user.id, amount: amount, description: description, type: type
  end

  def generate_post_manual_bill(amount, payment_type)
    post :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name,
                                user_prefix: @saved_user.id, amount: amount, payment_type: payment_type
  end

  def generate_put_toggle_testing_account
    put :toggle_testing_account, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id
  end

  test 'Change Next Bill Date for today' do
    correct_date = @saved_user.next_retry_bill_date
    post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, next_bill_date: Time.zone.now
    @saved_user.reload
    assert_equal(@saved_user.next_retry_bill_date, correct_date)
  end

  test 'Change Next Bill Date for yesterday' do
    correct_date = @saved_user.next_retry_bill_date
    post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, next_bill_date: Time.zone.now - 1.day
    @saved_user.reload
    assert_equal(@saved_user.next_retry_bill_date, correct_date)
  end

  test 'should get set_undeliverable' do
    %w[admin supervisor fulfillment_managment].each do |role|
      @agent.update_attribute :roles, role
      get :set_undeliverable, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id
      assert_response :success
    end
  end

  test 'should post set_undeliverable' do
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      post :set_undeliverable, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, wrong_address: true
      assert_response :redirect
    end
  end

  test 'should get set_unreachable' do
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      get :set_unreachable, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id
      assert_response :success
    end
  end

  test 'should post set_unreachable' do
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      post :set_unreachable, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, wrong_phone_number: true
      assert_response :redirect
    end
  end

  test 'should get to bill event section' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      get :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id
      assert_response :success
    end
  end

  test 'should not get to bill event section' do
    FactoryBot.create(:simple_club_with_gateway)
    club_role = ClubRole.new club_id: @club.id
    club_role.agent_id = @agent.id
    %w[representative api agency fulfillment_managment landing].each do |role|
      @agent.update_attribute :roles, role
      get :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id
      assert_response :unauthorized
    end
  end

  test 'One time billing' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, 'testing billing event', 'one-time')
      assert_response :success
    end
  end

  test 'Donation billing' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[admin supervisor].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, 'testing billing event', 'donation')
      assert_response :success
    end
  end

  test 'should not bill an event' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[representative api agency fulfillment_managment landing].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, 'testing billing event', 'one-time')
      assert_response :unauthorized
    end
  end

  test 'billing event with negative amount' do
    FactoryBot.create(:simple_club_with_gateway)
    generate_post_bill_event(-100, 'testing billing event', 'one-time')
    assert_response :success
    assert @response.body.include?('Amount must be greater than 0.')
  end

  test 'should manual bill' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[admin supervisor representative].each do |role|
      @agent.update_attribute :roles, role
      generate_post_manual_bill(200, 'cash')
      assert_response :success
    end
  end

  test 'should not manual bill' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[api agency fulfillment_managment].each do |role|
      @agent.update_attribute :roles, role
      generate_post_manual_bill(200, 'cash')
      assert_response :unauthorized
    end
  end

  test 'should toggle testing account value' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[admin supervisor fulfillment_managment representative landing].each do |role|
      @agent.update_attribute :roles, role
      generate_put_toggle_testing_account
      assert_response :redirect
    end
  end

  test 'should not toggle testing account value' do
    FactoryBot.create(:simple_club_with_gateway)
    %w[api agency].each do |role|
      @agent.update_attribute :roles, role
      generate_put_toggle_testing_account
      assert_response :unauthorized
    end
  end

  test 'should resend communication' do
    sign_in @agent
    @tom            = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'TOM for Email Templates Test')
    @email_template = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
    @communication  =
      Communication.create(user: @saved_user, template_name: @email_template.name, client: @email_template.client)
    post :resend_communication, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, communication_id: @communication.id
    assert_response :redirect
  end

  test 'should not resend communication' do
    @tom            = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'TOM for Email Templates Test')
    @email_template = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @tom.id)
    @communication  = Communication.create(user: @saved_user, template_name: @email_template.name, client: @email_template.client)
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_api_agent confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryBot.create agent
      perform_call_as(@agent) do
        post :resend_communication, partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, communication_id: @communication.id
        assert_response :unauthorized
      end
    end
  end
end
