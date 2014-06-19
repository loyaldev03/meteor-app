require 'test_helper'

class TermsOfMembershipsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_user = FactoryGirl.create(:confirmed_agency_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Admin_by_club should not see subcription plan information from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @other_club.id    
    get :show, id: @tom, partner_prefix: @partner.prefix, club_prefix: @other_club.name
    assert_response :unauthorized
  end

  test "Admin_by_club should see subcription plan information from its club" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @tom = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id    
    @tom.save
    get :show, id: @tom, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end
end
