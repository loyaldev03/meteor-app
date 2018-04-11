require 'test_helper'

class Api::CampaignsControllerTest < ActionController::TestCase
  setup do
    @landing_user = FactoryGirl.create(:confirmed_landing_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)    
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )   
    @preference_group = FactoryGirl.create(:preference_group_with_preferences, :club_id => @club.id)    
    @preference_group1 = FactoryGirl.create(:preference_group_with_preferences, :club_id => @club.id)    
    @campaign.preference_groups <<  @preference_group  
    @campaign.preference_groups <<  @preference_group1 
    @product = FactoryGirl.create(:random_product, :club_id => @club_id)
    @product1 = FactoryGirl.create(:random_product, :club_id => @club_id)
    @campaign.products << @product 
    @campaign.products << @product1
    @campaign1 = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )   
    @campaign1.preference_groups <<  @preference_group  
    @campaign1.preference_groups <<  @preference_group1

  end

  test "Agents that should return products and preferences when pass a campaign id" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = get(:metadata, { :id => @campaign, :format => :json} )    
        assert_response :success
        assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
        assert_equal false, JSON::parse(result.body)['without_products_assigned']
     
        json_products = JSON.parse(result.body)['get_products']
        @campaign.products.each do |products|
          products.campaign_products.each do |label|
            assert json_products.select {|product| product["id"] == products.id  && product["name"] == label.label && product["sku"] == products.sku && product["image_url"] == products.image_url}.any?
          end 
        end    

        preference_infos = JSON.parse(result.body)['get_preferences']
        @campaign.preference_groups.each do |preference_group|
          preference_group.preferences.each do |preference|      
            assert preference_infos.select{|preference_info| preference_info["group_code"] == preference_group.code && preference_info["id"] == preference.id && preference_info["name"] == preference.name}.any?
          end
        end
      end
    end  
  end

  test "Agents that should NOT return products and preferences when pass a campaign id" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent,].each do |agent|
      sign_agent_with_global_role(agent)
        perform_call_as(@agent) do
          result = get(:metadata, { :id => @campaign, :format => :json} )    
          assert_response :unauthorized 
      end
    end  
  end

  test "Agents that should answer campaign not found if invalid campaign_id is used." do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = get(:metadata, { :id => '123', :format => :json} )
        assert_response :success
        assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
      end
    end
  end

  test "Agents that should return only preferences when campaign id does not have products" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = get(:metadata, { :id => @campaign1, :format => :json} )    
        assert_response :success
        assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
        assert_equal true, JSON::parse(result.body)['without_products_assigned'] 
        assert_equal ([]), JSON::parse(result.body)['get_products']
  
        preference_infos = JSON.parse(result.body)['get_preferences']
        @campaign1.preference_groups.each do |preference_group|
          preference_group.preferences.each do |preference|      
            assert preference_infos.select{|preference_info| preference_info["group_code"] == preference_group.code && preference_info["id"] == preference.id && preference_info["name"] == preference.name}.any?
          end
        end
      end
    end 
  end

  test "Agents that should NOT return preferences when campaign id does not have products" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent,].each do |agent|
      sign_agent_with_global_role(agent)
        perform_call_as(@agent) do
          result = get(:metadata, { :id => @campaign1, :format => :json} )    
          assert_response :unauthorized 
      end
    end  
  end 
  

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "Agents with club roles that should return products and preferences when pass a campaign id" do
    ['admin', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do  
        result = get(:metadata, { :id => @campaign, :format => :json} )    
        assert_response :success
        assert_equal Settings.error_codes.success, JSON::parse(result.body)['code'] 
        assert_equal false, JSON::parse(result.body)['without_products_assigned']

        json_products = JSON.parse(result.body)['get_products']
        @campaign.products.each do |products|
          products.campaign_products.each do |label|
            assert json_products.select {|product| product["id"] == products.id  && product["name"] == label.label && product["sku"] == products.sku && product["image_url"] == products.image_url}.any?
          end 
        end    

        preference_infos = JSON.parse(result.body)['get_preferences']
        @campaign.preference_groups.each do |preference_group|
          preference_group.preferences.each do |preference|      
            assert preference_infos.select{|preference_info| preference_info["group_code"] == preference_group.code && preference_info["id"] == preference.id && preference_info["name"] == preference.name}.any?
          end
        end
      end
    end  
  end

  test "Agents with club roles that should NOT return products and preferences when pass a campaign id" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do  
          result = get(:metadata, { :id => @campaign, :format => :json} )    
          assert_response :unauthorized 
      end
    end  
  end

  test "Agents with club roles that should answer campaign not found if invalid campaign_id is used." do
    ['admin', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do  
        result = get(:metadata, { :id => '123', :format => :json} )
        assert_response :success
        assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
      end
    end
  end

  test "Agents with club roles that should return only preferences when campaign id does not have products" do
    ['admin', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        result = get(:metadata, { :id => @campaign1, :format => :json} )    
        assert_response :success
        assert_equal Settings.error_codes.success, JSON::parse(result.body)['code']
        assert_equal true, JSON::parse(result.body)['without_products_assigned'] 
        assert_equal ([]), JSON::parse(result.body)['get_products']
  
        preference_infos = JSON.parse(result.body)['get_preferences']
        @campaign1.preference_groups.each do |preference_group|
          preference_group.preferences.each do |preference|      
            assert preference_infos.select{|preference_info| preference_info["group_code"] == preference_group.code && preference_info["id"] == preference.id && preference_info["name"] == preference.name}.any?
          end
        end
      end
    end 
  end

  test "Agents with club roles that should NOT return preferences when campaign id does not have products" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do  
          result = get(:metadata, { :id => @campaign1, :format => :json} )    
          assert_response :unauthorized 
      end
    end  
  end
end