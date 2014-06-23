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

  def update_status_on_fulfillment_where_i_do_not_manage(profile)
      # setup member from other club
    @other_club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway_other_club = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @other_club.id)
    @other_club_saved_member = create_active_member(@terms_of_membership_with_gateway_other_club, :active_member, nil, {}, { :created_by => @admin_user })
    3.times{FactoryGirl.create(:fulfillment, :member_id => @other_club_saved_member.id, :product_sku => 'KIT-CARD', :club_id => @other_club.id)}

    # setup my member and login as club role fulfillment manager
    @my_club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway_my_club = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @my_club.id)

    @agent_club_role = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => @my_club.id
    club_role.role = profile
    club_role.agent_id = @agent_club_role.id
    club_role.save    

    @my_club_saved_member = create_active_member(@terms_of_membership_with_gateway_my_club, :active_member, nil, {}, { :created_by => @agent_club_role })
    3.times{FactoryGirl.create(:fulfillment, :member_id => @my_club_saved_member.id, :product_sku => 'KIT-CARD', :club_id => @my_club.id)}

    sign_in @agent_club_role

    assert_equal @other_club_saved_member.fulfillments.where(status: 'not_processed').count, 3
    assert_equal @my_club_saved_member.fulfillments.where(status: 'not_processed').count, 3

    # try to change status on other club fulfillment
    other_fulfillment = @other_club_saved_member.fulfillments.first
    response = put :update_status, partner_prefix: @my_club.partner.prefix, club_prefix: @my_club.name, new_status: 'out_of_stock', reason: 'test', file: nil, id: other_fulfillment.id
    assert response.body.include?("\"code\":\"414\""), "Response code invalid"
    assert_response :success

    other_fulfillment.reload
    assert_equal other_fulfillment.status, 'not_processed'
    assert_equal 0, @other_club_saved_member.fulfillments.where(status: 'out_of_stock').count


    # try to change status on my club fulfillment
    my_fulfillment = @my_club_saved_member.fulfillments.first
    response = put :update_status, partner_prefix: @my_club.partner.prefix, club_prefix: @my_club.name, new_status: 'out_of_stock', reason: 'test2', id: my_fulfillment.id

    assert response.body.include?("\"code\":\"000\""), "Response code invalid"
    assert_response :success

    my_fulfillment.reload
    assert_equal my_fulfillment.status, 'out_of_stock'
    assert_equal 1, @my_club_saved_member.fulfillments.where(status: 'out_of_stock').count
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

  test "Fulfillment Manager should not change status of fulfilments from other club that it does not manage" do
    update_status_on_fulfillment_where_i_do_not_manage('fulfillment_managment')
  end
  
  test "Admin by role should not change status of fulfilments from other club that it does not manage" do
    update_status_on_fulfillment_where_i_do_not_manage('admin')
  end
end
