require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    sign_in @admin_user
    @product = FactoryGirl.create(:product)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:club, :partner_id => @partner.id)
  end

  test "Admin should get index" do
    get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  test "Admin should get new" do
    get :new, :partner_prefix => @partner.prefix, :club_prefix => @club.name
    assert_response :success
  end

  # test "should create product" do
  #   assert_difference('Product.count') do
  #     post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, product: { name: @product.name,
  #                    recurrent: @product.recurrent, sku: @product.sku, stock: @product.stock, weight: @product.weight }
  #   end
  #   assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  # end

  test "Admin should show product" do
    get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Admin should get edit" do
    get :edit, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Admin should update product" do
    put :update, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name, 
                 product: { name: @product.name, recurrent: @product.recurrent, sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_redirected_to product_path(assigns(:product), :partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  test "Admin should destroy product" do
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
    end

    assert_redirected_to products_path
  end
end
