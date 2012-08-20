require 'test_helper'

class Api::ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @product = FactoryGirl.create(:product, :club_id => 1)
    sign_in @admin_user
  end

  test "should get stock." do
    result = get(:get_stock, { :club_id => @product.club_id, :sku => @product.sku, :format => :json} )
    assert_response :success
    assert result.code, Settings.error_codes.not_found
  end

  test "should answer product not found if invalid id is used." do
    result = get(:get_stock, { :club_id => @product.club_id, :sku => 'Bracelet1', :format => :json} )
    assert_response :success
    assert result.code, Settings.error_codes.not_found
  end

end