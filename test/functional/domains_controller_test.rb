require 'test_helper'

class DomainsControllerTest < ActionController::TestCase
  def setup
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @partner = FactoryGirl.create(:partner)
    @partner_prefix = @partner.prefix
    @domain = FactoryGirl.create(:domain, :partner_id => @partner.id )
  end

  test "Admin should get index" do
    sign_in @admin_user
    get :index, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get index" do
    sign_in @representative_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get index" do
    sign_in @supervisor_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get index" do
    sign_in @api_user
    get :index, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should get new" do
    sign_in @admin_user
    get :new, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get new" do
    sign_in @representative_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get new" do
    sign_in @supervisor_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get new" do
    sign_in @api_user
    get :new, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should create domain" do
    sign_in @admin_user
    domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
    assert_difference('Domain.count',1) do
      post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
        description: domain.description, hosted: domain.hosted, url: domain.url }
    end
    assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
  end

  test "Representative should not create domain" do
    sign_in @representative_user
    domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
    post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
        description: domain.description, hosted: domain.hosted, url: domain.url }
    assert_response :unauthorized
  end

  test "Supervisor should not create domain" do
    sign_in @supervisor_user
    domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
    post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
        description: domain.description, hosted: domain.hosted, url: domain.url } 
    assert_response :unauthorized
  end

  test "Api user should not create domain" do
    sign_in @api_user
    domain = FactoryGirl.build(:domain, :partner_id => @partner.id )
    post :create, partner_prefix: @partner_prefix, domain: { data_rights: domain.data_rights, 
        description: domain.description, hosted: domain.hosted, url: domain.url } 
    assert_response :unauthorized
  end

  test "Admin should show domain" do
    sign_in @admin_user
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not show domain" do
    sign_in @representative_user
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not show domain" do
    sign_in @supervisor_user
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not show domain" do
    sign_in @api_user
    get :show, id: @domain.id, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should get edit" do
    sign_in @admin_user
    get :edit, id: @domain, partner_prefix: @partner_prefix
    assert_response :success
  end

  test "Representative should not get edit" do
    sign_in @representative_user
    get :edit, id: @domain, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Supervisor should not get edit" do
    sign_in @supervisor_user
    get :edit, id: @domain, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Api user should not get edit" do
    sign_in @api_user
    get :edit, id: @domain, partner_prefix: @partner_prefix
    assert_response :unauthorized
  end

  test "Admin should update domain" do
    sign_in @admin_user
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_redirected_to domain_path(assigns(:domain), partner_prefix: @partner_prefix)
  end

  test "Representative should not update domain" do
    sign_in @representative_user
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_response :unauthorized
  end

  test "Supervisor should not update domain" do
    sign_in @supervisor_user
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_response :unauthorized
  end

  test "Api user should not update domain" do
    sign_in @api_user
    put :update, id: @domain, partner_prefix: @partner_prefix, domain: { data_rights: @domain.data_rights, description: @domain.description, hosted: @domain.hosted, url: @domain.url }
    assert_response :unauthorized
  end

  # test "should destroy domain" do
  #   assert_difference('Domain.count', -1) do
  #     delete :destroy, id: @domain.id, partner_prefix: @partner_prefix
  #   end
  #   assert_redirected_to domains_path
  # end
 end
