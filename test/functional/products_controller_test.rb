require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @product = FactoryGirl.create(:product)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product" do
    assert_difference('Product.count') do
      post :create, product: { club_id: @product.club_id, name: @product.name, recurrent: @product.recurrent, sku: @product.sku, stock: @product.stock, weight: @product.weight }
    end
    assert_redirected_to product_path(assigns(:product))
  end

  test "should show product" do
    get :show, id: @product
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product
    assert_response :success
  end

  test "should update product" do
    put :update, id: @product, product: { club_id: @product.club_id, name: @product.name, recurrent: @product.recurrent, sku: @product.sku, stock: @product.stock, weight: @product.weight }
    assert_redirected_to product_path(assigns(:product))
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product
    end

    assert_redirected_to products_path
  end
end
