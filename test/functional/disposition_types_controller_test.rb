require 'test_helper'

class DispositionTypesControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @representative_user = FactoryBot.create(:confirmed_representative_agent)
    @fulfillment_manager_user = FactoryBot.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user = FactoryBot.create(:confirmed_supervisor_agent)
    @api_user = FactoryBot.create(:confirmed_api_agent)
    @agency_user = FactoryBot.create(:confirmed_agency_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Admin_by_role should not see Disposition Type from another club where it has not permissions" do
    @club_admin = FactoryBot.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @dt = FactoryBot.create(:disposition_type)
    @dt.club_id = @other_club.id
    @dt.save
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @other_club.name
    assert_response :unauthorized
  end

  test "Admin_by_role should not edit Disposition Type from another club where it has not permissions" do
    @club_admin = FactoryBot.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @dt = FactoryBot.create(:disposition_type)
    @dt.club_id = @other_club.id
    @dt.save
    get :edit, id: @dt, partner_prefix: @partner.prefix, club_prefix: @other_club.name
    assert_response :unauthorized
  end

end