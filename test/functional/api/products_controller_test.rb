require 'test_helper'

class Api::ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @api_user = FactoryBot.create(:confirmed_api_agent)
    @representative_user = FactoryBot.create(:confirmed_representative_agent)
    @supervisor_user = FactoryBot.create(:confirmed_supervisor_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @product = FactoryBot.create(:product, :club_id => 1)
    
  end

  test "Request stock of multiple products" do
    sign_in @admin_user
    @product2 = FactoryBot.create(:product, :club_id => 2)
    @product3 = FactoryBot.create(:product, :club_id => 3)
    result = get(:get_list_of_stock, { :club_id => @product.club_id, :sku => "#{@product.sku},#{@product2.sku},#{@product3.sku}", :format => :json} )
    assert_response :success
    assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
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

  test "supervisor should not get stock." do
    sign_in @supervisor_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => @product.sku, :format => :json} )
    assert_response :unauthorized
  end

  test "supervisor should not answer product not found if invalid id is used." do
    sign_in @supervisor_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => 'Bracelet34', :format => :json} )
    assert_response :unauthorized
  end

  test "representative should not get stock." do
    sign_in @representative_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => @product.sku, :format => :json} )
    assert_response :unauthorized
  end
  
  test "representative should not answer product not found if invalid id is used." do
    sign_in @representative_user
    result = get(:get_stock, { :club_id => @product.club_id, :sku => 'Bracelet34', :format => :json} )
    assert_response :unauthorized
  end
end