require 'test_helper'

class Api::ProductsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @api_user = FactoryBot.create(:confirmed_api_agent)
    @representative_user = FactoryBot.create(:confirmed_representative_agent)
    @supervisor_user = FactoryBot.create(:confirmed_supervisor_agent)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
    @product = FactoryBot.create(:product, club_id: 1)
  end

  test 'Admin, Api, FulfillmentManagers and Agency agents can request stock' do
    %i[confirmed_admin_agent confirmed_api_agent
       confirmed_agency_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = get(:get_stock, club_id: @product.club_id, sku: @product.sku, format: :json)
        assert_response :success
        assert_equal Settings.error_codes.success, JSON.parse(result.body)['code']
      end
    end
  end

  test 'Admin, Api, FulfillmentManagers and Agency agents can request stock of multiple products' do
    @product2 = FactoryBot.create(:product, club_id: 2)
    @product3 = FactoryBot.create(:product, club_id: 3)
    %i[confirmed_admin_agent confirmed_api_agent
       confirmed_agency_agent confirmed_fulfillment_manager_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = get(:get_list_of_stock, club_id: @product.club_id, sku: "#{@product.sku},#{@product2.sku},#{@product3.sku}", format: :json)
        assert_response :success
        assert_equal Settings.error_codes.success, JSON.parse(result.body)['code']
      end
    end
  end

  test 'return product not found if invalid id is provided.' do
    sign_in @admin_user
    result = get(:get_stock, club_id: @product.club_id, sku: 'Bracelet34', format: :json)
    assert_response :success
    assert_equal Settings.error_codes.not_found, JSON.parse(result.body)['code']
  end

  test 'Supervisor, Representative and Landing Agents can not request stock.' do
    %i[confirmed_supervisor_agent confirmed_representative_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get(:get_stock, club_id: @product.club_id, sku: @product.sku, format: :json)
        assert_response :unauthorized
      end
    end
  end
end
