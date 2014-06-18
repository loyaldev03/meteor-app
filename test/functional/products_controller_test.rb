require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
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

  test "Admin should get new" do
    sign_in @admin_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Representative should not get new" do
    sign_in @representative_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Fulfillment manager should get new" do
    sign_in @fulfillment_manager_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Supervisor should not get new" do
    sign_in @supervisor_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Api user should not get new" do
    sign_in @api_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :unauthorized
  end

  test "Agency user should get new" do
    sign_in @agency_user
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Admin should create product" do
    sign_in @admin_user
    product = FactoryGirl.build(:product)
    assert_difference('Product.count',1) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: product.name,
                     recurrent: product.recurrent, package: product.package, sku: product.sku, stock: product.stock, weight: product.weight }
    end
    assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  test "Representative should not create product" do
    sign_in @representative_user
    product = FactoryGirl.build(:product)
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: product.name,
                     recurrent: product.recurrent, package: product.package, sku: product.sku, stock: product.stock, weight: product.weight }
    assert_response :unauthorized
  end

  test "Supervisor should not create product" do
    sign_in @supervisor_user
    product = FactoryGirl.build(:product)
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: product.name,
                     recurrent: product.recurrent, package: product.package, sku: product.sku, stock: product.stock, weight: product.weight }
    assert_response :unauthorized
  end

  test "Api user should not create product" do
    sign_in @api_user
    product = FactoryGirl.build(:product)
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: product.name,
                     recurrent: product.recurrent, sku: product.sku, stock: product.stock, weight: product.weight }
    assert_response :unauthorized
  end

  test "Agency user should create product" do
    sign_in @agency_user
    product = FactoryGirl.build(:product)
    assert_difference('Product.count',1) do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: product.name,
                     recurrent: product.recurrent, package: product.package, sku: product.sku, stock: product.stock, weight: product.weight }
    end
    assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  test "Admin should show product" do
    sign_in @admin_user
    @product = FactoryGirl.create(:product)
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Representative should not show product" do
    sign_in @representative_user
    @product = FactoryGirl.create(:product)
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Supervisor should not show product" do
    sign_in @supervisor_user
    @product = FactoryGirl.create(:product)
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Api user should not show product" do
    sign_in @api_user
    @product = FactoryGirl.create(:product)
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Agency user should show product" do
    sign_in @admin_user
    @product = FactoryGirl.create(:product)
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Admin should get edit" do
    sign_in @admin_user
    @product = FactoryGirl.create(:product)
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Representative should not get edit" do
    sign_in @representative_user
    @product = FactoryGirl.create(:product)
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Supervisor should not get edit" do
    sign_in @supervisor_user
    @product = FactoryGirl.create(:product)
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Api user should not get edit" do
    sign_in @api_user
    @product = FactoryGirl.create(:product)
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Agency user should get edit" do
    sign_in @agency_user
    @product = FactoryGirl.create(:product)
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Admin should update product" do
    sign_in @admin_user
    @product = FactoryGirl.create(:product)
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, package: @product.package, sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  test "Representative should not update product" do
    sign_in @representative_user
    @product = FactoryGirl.create(:product)
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, package: @product.package,sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_response :unauthorized
  end

  test "Supervisor should not update product" do
    sign_in @supervisor_user
    @product = FactoryGirl.create(:product)
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, package: @product.package,sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_response :unauthorized
  end

  test "Api user should not update product" do
    sign_in @api_user
    @product = FactoryGirl.create(:product)
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, package: @product.package,sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_response :unauthorized
  end

  test "Agency user should update product" do
    sign_in @agency_user
    @product = FactoryGirl.create(:product)
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, package: @product.package,sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  test "Admin should destroy product" do
    sign_in @admin_user
    @product = FactoryGirl.create(:product)   
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    end
    assert_redirected_to products_path
  end

  test "Representative should not destroy product" do
    sign_in @representative_user
    @product = FactoryGirl.create(:product) 
    delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Supervisor should not destroy product" do
    sign_in @supervisor_user
    @product = FactoryGirl.create(:product) 
    delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Api user should not destroy product" do
    sign_in @api_user
    @product = FactoryGirl.create(:product) 
    delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Agency user should destroy product" do
    sign_in @agency_user
    @product = FactoryGirl.create(:product)   
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    end
    assert_redirected_to products_path
  end

  test "Admin_by_role can not see product from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @product = FactoryGirl.create(:product)
    @product.club_id = @other_club.id
    @product.save
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

  test "Admin_by_role can not edit product from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    product = FactoryGirl.build(:product)
    post :create, partner_prefix: @partner.prefix, 
      club_prefix: @other_club.name, 
      product: {
        name: product.name, recurrent: product.recurrent, package: product.package, 
        sku: product.sku, stock: product.stock, weight: product.weight, club_id: @other_club.id
      }
    assert_response :unauthorized
  end

  test "Admin_by_role can not delete products from another club where it has not permissions" do
    @club_admin = FactoryGirl.create(:confirmed_admin_agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @club_admin.id
    club_role.role = "admin"
    club_role.save
    @club_admin.roles = nil
    @club_admin.save
    sign_in(@club_admin)
    @other_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @product = FactoryGirl.create(:product)
    @product.club_id = @other_club.id
    @product.save
    delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :unauthorized
  end

end
