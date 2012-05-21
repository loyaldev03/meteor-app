require 'test_helper'

class ClubsControllerTest < ActionController::TestCase
  def setup
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @club = FactoryGirl.create(:club, :partner_id => @partner.id)
  end

  test "should get index" do
    get :index, partner_prefix: @partner_prefix
    assert_response :success
    assert_not_nil assigns(:clubs)
  end

  test "should get new" do
    get :new, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should create club" do
    @club = FactoryGirl.build(:club, :partner_id => @partner.id)
    assert_difference('Club.count') do
      post :create, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    end

    assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
  end

  test "should show club" do
    get :show, id: @club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @club, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should update club" do
    put :update, id: @club, partner_prefix: @partner_prefix, club: { description: @club.description, name: @club.name }
    assert_redirected_to club_path(assigns(:club), partner_prefix: @partner_prefix)
  end

  test "should destroy club" do
    assert_difference('Club.count', -1) do
      delete :destroy, id: @club, partner_prefix: @partner_prefix
    end

    assert_redirected_to clubs_path
  end
end
