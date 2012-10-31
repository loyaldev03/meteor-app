require 'test_helper'

class MembersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_user = FactoryGirl.create(:confirmed_agency_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:club, :partner_id => @partner.id)
    @saved_member = FactoryGirl.create(:member_with_api, :club_id => @club.id, :next_retry_bill_date => Time.zone.now+5)
  	@saved_member = Member.last
  end

  test "Change Next Bill Date for today" do
  	correct_date = @saved_member.next_retry_bill_date
		post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.visible_id, next_bill_date: Time.zone.now
		@saved_member.reload
		assert_equal(@saved_member.next_retry_bill_date, correct_date )
	end

  test "Change Next Bill Date for yesterday" do
  	correct_date = @saved_member.next_retry_bill_date
		post :change_next_bill_date, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.visible_id, next_bill_date: Time.zone.now-1
		@saved_member.reload
		assert_equal(@saved_member.next_retry_bill_date, correct_date )
	end
end
