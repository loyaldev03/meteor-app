require 'test_helper'

class MembersControllerTest < ActionController::TestCase
  setup do
    @agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:club, :partner_id => @partner.id)
    @saved_member = FactoryGirl.create(:member_with_api, :club_id => @club.id, :next_retry_bill_date => Time.zone.now+5.day)
  	@saved_member = Member.last
    sign_in @agent
  end

  def generate_post_bill_event(amount, description, type)
    post :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                                member_prefix: @saved_member.id, amount: amount, description: description, :type => type
  end

  def generate_post_manual_bill(amount, payment_type)
    post :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                                member_prefix: @saved_member.id, amount: amount, payment_type: payment_type
  end

  test "Change Next Bill Date for today" do
  	correct_date = @saved_member.next_retry_bill_date
		post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id, next_bill_date: Time.zone.now
		@saved_member.reload
		assert_equal(@saved_member.next_retry_bill_date, correct_date )
	end

  test "Change Next Bill Date for yesterday" do
  	correct_date = @saved_member.next_retry_bill_date
		post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id, next_bill_date: Time.zone.now-1.day
		@saved_member.reload
		assert_equal(@saved_member.next_retry_bill_date, correct_date )
	end

  test "should get to bill event section" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['admin', 'supervisor'].each do |role|
      @agent.update_attribute :roles, role
      get :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id
      assert_response :success
    end
  end

  test "should not get to bill event section" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      @agent.update_attribute :roles, role
      get :no_recurrent_billing, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id
      assert_response :unauthorized
    end
  end

  test "One time billing" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['admin', 'supervisor'].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, "testing billing event", "one-time")
      assert_response :success
    end
  end

  test "Donation billing" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['admin', 'supervisor'].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, "testing billing event", "donation")
      assert_response :success
    end
  end

  test "should not bill an event" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      @agent.update_attribute :roles, role
      generate_post_bill_event(200, "testing billing event", "one-time")
      assert_response :unauthorized
    end
  end
  
  test "billing event with negative amount" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    generate_post_bill_event(-100, "testing billing event", "one-time")
    assert_response :success
    assert @response.body.include?("Amount must be greater than 0.")
  end

  test "should manual bill" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['admin', 'supervisor', 'representative'].each do |role|
      @agent.update_attribute :roles, role
      generate_post_manual_bill(200, "cash")
      assert_response :success
    end
  end

  test "should not manual bill" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['api', 'agency', 'fulfillment_managment'].each do |role|
      @agent.update_attribute :roles, role
      generate_post_manual_bill(200, "cash")
      assert_response :unauthorized
    end
  end
end
