require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Agents should get index" do
    [:confirmed_admin_agent, :confirmed_fulfillment_manager_agent,
      :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent) 
      perform_call_as(@agent) do    
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :success
      end
    end
  end
  
  test "Agents that should not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do  
        get :index, :partner_prefix => @partner.prefix, :club_prefix => @club.name
        assert_response :unauthorized
      end
    end
  end

  test "Agents that should show product" do
    [:confirmed_admin_agent, :confirmed_fulfillment_manager_agent,
      :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do 
        @product = FactoryGirl.create(:random_product)
        get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :success
      end
    end
  end

  test "Agents that should not show product" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @product = FactoryGirl.create(:random_product)
        get :show, id: @product, partner_prefix: @partner.prefix, club_prefix: @club.name
        assert_response :unauthorized
      end
    end    
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
end
