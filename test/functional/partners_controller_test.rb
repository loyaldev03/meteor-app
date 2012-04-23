require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
  end

  test "should get index" do
    get :index, partner_prefix: @partner_prefix
    assert_response :success
    assert_not_nil assigns(:partners)
  end

  test "should get new" do
    get :new, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should create domain" do
    assert_difference('Domain.count') do
      post :create, partner_prefix: @partner_prefix, partner: { :prefix => @partner_pregix, :name => @partner.name, :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, :description => @partner.description, :logo => @partner.logo }
    end

    assert_redirected_to partner_path(assigns(:partner), partner_prefix: @partner_prefix)
  end

  test "should show domain" do
    get :show, id: @partner.id, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @partner, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should update domain" do
    put :update, id: @domain, partner_prefix: partner: { :prefix => @partner_pregix, :name => @partner.name, :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, :description => @partner.description, :logo => @partner.logo }
    assert_redirected_to partner_path(assigns(:partner), partner_prefix: @partner_prefix)
  end

  test "should destroy domain" do
    assert_difference('Partner.count', -1) do
      delete :destroy, id: @partner, partner_prefix: @partner_prefix
    end

    assert_redirected_to domains_path
  end
end
