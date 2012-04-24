require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  before(:each) do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @domain = FactoryGirl.create(:domain, :partner_id => @partner.id )
  end

  test "should get index" do
    get :index, partner_prefix: @partner_prefix
    assert_response :success
    assert_not_nil assigns(:domains)
  end

  test "should get new" do
    get :new, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should create domain" do
    assert_difference('Domain.count') do
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, deleted_at: @domain.deleted_at, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    end

    assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
  end

  test "should show domain" do
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @domain, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "should update domain" do
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, deleted_at: @domain.deleted_at, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
  end

  test "should destroy domain" do
    assert_difference('Domain.count', -1) do
      delete :destroy, id: @domain, partner_prefix: @partner_prefix
    end

    assert_redirected_to domains_path
  end
end
