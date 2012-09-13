require 'test_helper'

class Api::ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @product = FactoryGirl.create(:product, :club_id => 1)
    
  end

  test "admin should get stock." do
    sign_in @admin_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => @product.sku, :format => :json} )
    assert_response :success
    assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
  end

  test "admin should answer product not found if invalid id is used." do
    sign_in @admin_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => 'Bracelet34', :format => :json} )
    assert_response :success
    assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
  end

  test "api agent should get stock." do
    sign_in @api_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => @product.sku, :format => :json} )
    assert_response :success
    assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
  end

  test "api agent should answer product not found if invalid id is used." do
    sign_in @api_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => 'Bracelet34', :format => :json} )
    assert_response :success
    assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
  end
end