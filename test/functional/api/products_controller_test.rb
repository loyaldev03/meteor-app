require 'test_helper'

class Api::ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    sign_in @admin_user
  end

  test "should get stock." do
    product = FactoryGirl.create(:product, :club_id => 1)
    get(:get_stock, { :club_id => 1, :sku => 'Bracelet', :format => :json} )
    assert_response :success
  end

end