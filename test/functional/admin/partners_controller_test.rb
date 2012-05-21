require 'test_helper'
      
class Admin::PartnersControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:partners)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create partner" do
    partner = FactoryGirl.build(:partner)
    assert_difference('Partner.count') do
      post :create, partner: { :prefix => partner.prefix, :name => partner.name, :contract_uri => partner.contract_uri, :website_url => partner.website_url, :description => partner.description }
    end

    assert_redirected_to admin_partner_path(assigns(:partner))
  end

  test "should show partner" do
    get :show, id: @partner.id
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @partner
    assert_response :success
  end

  test "should update partner" do
    put :update, id: @partner, partner: { :prefix => @partner_pregix, :name => @partner.name, :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, :description => @partner.description }
    assert_redirected_to admin_partner_path(assigns(:partner))
  end

  test "should destroy partner" do
    assert_difference('Partner.count', -1) do
      delete :destroy, id: @partner
    end

    assert_redirected_to admin_partners_path
  end
end
