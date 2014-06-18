require 'test_helper'

class FulfillmentsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @fulfillment_manager_user = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_user = FactoryGirl.create(:confirmed_agency_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:club, :partner_id => @partner.id)
    @product = FactoryGirl.create(:product, :club_id => @club_id)
  end

  test "Admin should get index" do
    sign_in @admin_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end
  
  test "Representative should not get index" do
    sign_in @representative_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Fulfillment manager should get index" do
    sign_in @fulfillment_manager_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Supervisor should not get index" do
    sign_in @supervisor_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Api user should not get index" do
    sign_in @api_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Agency user should not get index" do
    sign_in @agency_user
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Admin_by_role should not see fulfillment files from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @ff_file = FactoryGirl.create(:fulfillment_file)
    @ff_file.club_id = @other_club.id
    @ff_file.save
    get :list_for_file, fulfillment_file_id: @ff_file, partner_prefix: @partner.prefix, club_prefix: @other_club.name
    assert_response :unauthorized
  end

  test "Admin_by_role should not update fulfillment status from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @ff_file = FactoryGirl.create(:fulfillment_file)
    @ff_file.club_id = @other_club.id
    @ff_file.save
    put :update_status, id: @ff_file, partner_prefix: @partner.prefix, club_prefix: @other_club.name, fulfillment_file: {status: 'sent'}
    assert_response :unauthorized
  end

  test "Admin_by_role should not Export to XLS fulfillments from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @ff_file = FactoryGirl.create(:fulfillment_file)
    @ff_file.club_id = @other_club.id
    @ff_file.save
    get :generate_xls, id: @ff_file, partner_prefix: @partner.prefix, club_prefix: @other_club.name
    assert_response :unauthorized
  end
end
