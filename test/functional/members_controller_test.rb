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
      @agent.update_attribute :roles, [role]
      get :bill_event, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id
      assert_response :success
    end
  end

  test "should not get to bill event section" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      @agent.update_attribute :roles, [role]
      get :bill_event, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id
      assert_response :unauthorized
    end
  end

  test "should bill an event" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    ['admin', 'supervisor'].each do |role|
      @agent.update_attribute :roles, [role]
      post :bill_event, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id, amount: 200, description: "testing bill."
      assert_response :success
    end
  end

  test "should not bill an event" do
    club = FactoryGirl.create(:simple_club_with_gateway)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    ['representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      @agent.update_attribute :roles, [role]
      post :bill_event, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.id, amount: 200, description: "testing bill."
      assert_response :unauthorized
    end
  end

end
