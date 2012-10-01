require 'test_helper'

class FulfillmentsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
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
end