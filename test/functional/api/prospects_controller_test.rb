require 'test_helper'

class Api::ProspectsControllerTest < ActionController::TestCase
  setup do
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create :terms_of_membership_with_gateway, :club_id => @club.id
    @campaign = FactoryBot.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )   
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

  def do_post
    post( :create, { prospect: {:first_name => @user.first_name, 
                                :last_name => @user.last_name,
                                :address => @user.address,
                                :gender => 'M',
                                :city => @user.city, 
                                :zip => @user.zip,
                                :state => @user.state,
                                :email => @user.email,
                                :country => @user.country,
                                :type_of_phone_number => @user.type_of_phone_number,
                                :phone_country_code => @user.phone_country_code,
                                :phone_area_code => @user.phone_area_code,
                                :phone_local_number => @user.phone_local_number,
                                :terms_of_membership_id => @terms_of_membership.id,
                                :birth_date => @user.birth_date,
                                :product_description => @enrollment_info.product_description,
                                :audience => @enrollment_info.audience,
                                :utm_medium => @enrollment_info.utm_medium,
                                :campaign_description => @enrollment_info.campaign_description,
                                :utm_content => @enrollment_info.utm_content,
                                :campaign_id => @enrollment_info.campaign_code,
                                :utm_campaign => @enrollment_info.utm_campaign,
                                :ip_address => @enrollment_info.ip_address,
                                :referral_host => @enrollment_info.referral_host,
                                :referral_path => @enrollment_info.referral_path,
                                :ip_address => @enrollment_info.ip_address,
                                :user_agent => @enrollment_info.user_agent,                               
                                :landing_url => @enrollment_info.landing_url,
                                :preferences => @enrollment_info.preferences,
                                :cookie_set => @enrollment_info.cookie_set,
                                :cookie_value => @enrollment_info.cookie_value,
                                :utm_source => @enrollment_info.utm_source,
                                :joint => @enrollment_info.joint,
                              },:format => :json})
  end

  test "admin and api user should create a prospect" do
    [:confirmed_admin_agent, :confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
        @current_club = @terms_of_membership.club
        assert_difference('Operation.count') do
          assert_difference('Prospect.count') do
            do_post
            assert_response :success
            prospect = Prospect.find JSON.parse(response.body)["prospect_id"]
            assert_equal prospect.utm_source, @enrollment_info.utm_source
          end
        end
        assert_equal(Prospect.first.club_id, @terms_of_membership.club_id)
      end
    end
  end

  test "agents that should not create a prospect" do    
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_fulfillment_manager_agent, 
     :confirmed_agency_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do     
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build :membership_with_enrollment_info
        @current_club = @terms_of_membership.club
        assert_difference('Prospect.count',0) do
          do_post
          assert_response :unauthorized 
        end 
      end
    end
  end

  test "try to create a prospect without sending params" do
    [:confirmed_admin_agent, :confirmed_api_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build :membership_with_enrollment_info
        @current_club = @terms_of_membership.club
        post( :create, {:format => :json})
        assert @response.body.include? "There are some params missing. Please check them."
        assert_response :success

        post( :create, {:first_name => @user.first_name, :format => :json})
        assert @response.body.include? "There are some params missing. Please check them."
        assert_response :success
      end
    end
  end

  test "Agents that should show prospect" do
    [ :confirmed_admin_agent, :confirmed_api_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        prospect = FactoryBot.create(:prospect, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)        
        token = prospect.token
        result = post(:show, { :token => token, :format => :json} ) 
        assert_response :success

        json_prospect = JSON.parse(result.body)['prospect']
        assert_equal json_prospect["email"], prospect.email
        assert_equal json_prospect["first_name"], prospect.first_name
        assert_equal json_prospect["last_name"], prospect.last_name
        assert_equal json_prospect["address"], prospect.address
        assert_equal json_prospect["state"], prospect.state
        assert_equal json_prospect["zip"], prospect.zip
        assert_equal json_prospect["preferences"], prospect.preferences
        assert_equal json_prospect["product_sku"], prospect.product_sku
        assert_equal json_prospect["country"], prospect.country
        assert_nil json_prospect["error_messages"] 
      end  
    end
  end

  test "Agents that should not show prospect when it has an invalid token" do
    [ :confirmed_admin_agent, :confirmed_api_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        result = post(:show, { :token => 123, :format => :json} )     
        assert_response :success
        assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
      end
    end
  end

  test "Agents that should not show prospect" do
    [ :confirmed_supervisor_agent, :confirmed_representative_agent, 
      :confirmed_fulfillment_manager_agent, 
      :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        prospect = FactoryBot.create(:prospect, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)        
        token = prospect.token
        result = post(:show, { :token => token, :format => :json} ) 
        assert_response :unauthorized
      end
    end
  end

  ####################################################
  #################CLUBS ROLES########################
  #################################################### 

  test "admin and api user with club role should create a prospect" do
    ['admin', 'api'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do 
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
        @current_club = @terms_of_membership.club
        assert_difference('Operation.count') do
          assert_difference('Prospect.count') do
            do_post
            assert_response :success
            prospect = Prospect.find JSON.parse(response.body)["prospect_id"]
            assert_equal prospect.utm_source, @enrollment_info.utm_source
          end
        end
        assert_equal(Prospect.first.club_id, @terms_of_membership.club_id)
      end
    end
  end

  test "agents with club role that should not create a prospect" do    
    ['supervisor', 'representative', 'agency', 'fulfillment_managment', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do    
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build :membership_with_enrollment_info
        @current_club = @terms_of_membership.club
        assert_difference('Prospect.count',0) do
          do_post
          assert_response :unauthorized 
        end 
      end
    end
  end

  test "agents with club role trying to create a prospect without sending params" do
    ['admin', 'api'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        @user = FactoryBot.build :user_with_api
        @enrollment_info = FactoryBot.build :membership_with_enrollment_info
        @current_club = @terms_of_membership.club
        post( :create, {:format => :json})
        assert @response.body.include? "There are some params missing. Please check them."
        assert_response :success

        post( :create, {:first_name => @user.first_name, :format => :json})
        assert @response.body.include? "There are some params missing. Please check them."
        assert_response :success
      end
    end
  end

  test "Agents with club role that should show prospect" do
    ['admin', 'api', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        prospect = FactoryBot.create(:prospect, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)        
        token = prospect.token
        result = post(:show, { :token => token, :format => :json} ) 
        assert_response :success

        json_prospect = JSON.parse(result.body)['prospect']
        assert_equal json_prospect["email"], prospect.email
        assert_equal json_prospect["first_name"], prospect.first_name
        assert_equal json_prospect["last_name"], prospect.last_name
        assert_equal json_prospect["address"], prospect.address
        assert_equal json_prospect["state"], prospect.state
        assert_equal json_prospect["zip"], prospect.zip
        assert_equal json_prospect["preferences"], prospect.preferences
        assert_equal json_prospect["product_sku"], prospect.product_sku
        assert_equal json_prospect["country"], prospect.country
        assert_nil json_prospect["error_messages"]  
      end  
    end
  end

  test "Agents with club role that should not show prospect when it has an invalid token" do
    ['admin', 'api', 'landing'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        result = post(:show, { :token => 123, :format => :json} )     
        assert_response :success
        assert_equal Settings.error_codes.not_found, JSON::parse(result.body)['code']
      end
    end
  end

  test "Agents with club role that should not show prospect" do
    ['supervisor', 'representative', 'agency', 'fulfillment_managment'].each do |role|      
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        prospect = FactoryBot.create(:prospect, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)        
        token = prospect.token
        result = post(:show, { :token => token, :format => :json} ) 
        assert_response :unauthorized
      end
    end
  end
end

