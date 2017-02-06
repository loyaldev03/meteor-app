require 'test_helper'

class Campaigns::CheckoutsControllerTest < ActionController::TestCase

  def setup
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)
    @prospect = FactoryGirl.create(:prospect, :club_id => @club.id)
    @credit_card = FactoryGirl.create :credit_card_american_express
  end

  def sign_agent_with_global_role(type)
    @agent = FactoryGirl.create type
    sign_in @agent
  end

  def sign_agent_with_club_role(type, role)
    @agent = FactoryGirl.create(type, roles: '')
    ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
    sign_in @agent
  end

  def generate_submit_post(campaign_id, prospect, terms_of_membership_id, api_key)
    post :submit, landing_id:campaign_id, first_name: prospect.first_name, last_name: prospect.last_name,
                address: prospect.address, city: prospect.city, state: prospect.state, gender: prospect.gender, zip: prospect.zip,
                phone: prospect.phone, email: prospect.email, country: prospect.country, terms_of_membership_id:terms_of_membership_id,
                api_key: api_key
  end

  test "Admin and landing roles should submit checkout" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)

      assert_difference('Prospect.count',1) do
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id)
        generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      end
      prospect = Prospect.last
      assert_redirected_to new_checkout_path(campaign_id: @campaign.to_param, token: prospect.token)
    end
  end

  test "Agents that should not submit checkout" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent,
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        assert_difference('Prospect.count',0) do
          prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id)
          generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
        end
      end
      assert_redirected_to error_checkout_path
    end
  end

  test "should not create prospect if the domain does not belong to the club" do
    @club1 = FactoryGirl.create(:simple_club_with_gateway, :checkout_url => "http://test2.host", :partner_id => @partner.id)
    @campaign1 = FactoryGirl.create(:campaign, :club_id => @club1.id, :terms_of_membership_id => @terms_of_membership.id)
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      assert_difference('Prospect.count',0) do
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club1.id)
        generate_submit_post(@campaign1.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      end
      assert_redirected_to error_checkout_path(campaign_id: @campaign1.to_param)
    end
  end

  test "should not create prospect if it has wrong campaign id" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      assert_difference('Prospect.count',0) do
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id)
        generate_submit_post(4565121, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      end
      assert_redirected_to critical_error_checkout_path
    end
  end

  test "should not create prospect if it has wrong data" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :first_name => 'M')
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"first_name"=>["is too short (minimum is 2 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :last_name => 'B')
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"last_name"=>["is too short (minimum is 2 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :first_name => 'Maarttiisswaarttiisswaarttiisswaarttiisswaarttiissweee')
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"first_name"=>["is too long (maximum is 50 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :last_name => 'Baarttiisswaarttiisswaarttiisswaarttiisswaarttiissweee')
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"last_name"=>["is too long (maximum is 50 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :zip => 123)
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"zip"=>["Unfortunately we are unable to ship outside of the United States at this time."]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :zip => 123451)
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"zip"=>["Unfortunately we are unable to ship outside of the United States at this time."]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :phone_country_code => 1, :phone_area_code => 56, :phone_local_number => 456)
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"phone"=>["Wrong phone number"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :email => "alicebrennan.com")
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"email"=>["Wrong email address"]})
      assert_response :redirect
    end
  end

  test "Admin and landing should get news" do
    [:confirmed_admin_agent, :confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      get :new, campaign_id:@campaign.to_param, token: @prospect.token
      assert_response :success
    end
  end

  test "admin and landing should create checkout" do
    [:confirmed_admin_agent, :confirmed_landing_agent ].each do |agent|
      sign_agent_with_global_role(agent)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id)
      assert_difference('User.count',1) do
       assert_difference('Membership.count', 1) do          
         post :create, credit_card: { campaign_id:@campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
       end
      end
      assert_redirected_to thank_you_checkout_path(campaign_id: @campaign.to_param, user_id: User.last.to_param)
    end 
  end

  test "agents that should not create checkout" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent,
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        prospect = FactoryGirl.create(:prospect, :club_id => @club.id)
        assert_difference('User.count',0) do
          assert_difference('Membership.count', 0) do
            post :create, credit_card: { campaign_id: @campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
          end
        end
        assert_redirected_to error_checkout_path
      end
    end
  end

  test "admin and landing should display duplicated_checkout" do
    [:confirmed_admin_agent, :confirmed_landing_agent ].each do |agent|
      sign_agent_with_global_role(agent)
      user = FactoryGirl.create(:active_user, :club_id => @club.id)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => user.email)
      assert_difference('User.count',0) do
        assert_difference('Membership.count', 0) do
          post :create, credit_card: { campaign_id: @campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
        end
      end      
      assert_redirected_to duplicated_checkout_path(campaign_id: @campaign.to_param, token: prospect.token)
    end
  end

  test "agents that should not display duplicated_checkout" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent,
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent,
     :confirmed_agency_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        user = FactoryGirl.create(:active_user, :club_id => @club.id)
        prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => user.email)
        assert_difference('User.count',0) do
          assert_difference('Membership.count', 0) do
            post :create, campaign_id:@campaign.to_param, prospect_id:prospect.id, credit_card: { :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }
          end
        end
        assert_redirected_to error_checkout_path
      end
    end
  end

  test "admin and landing should recover a user by checkout" do
    [:confirmed_admin_agent, :confirmed_landing_agent ].each do |agent|
      sign_agent_with_global_role(agent)
      lapsed_user = FactoryGirl.create(:lapsed_user, :club_id => @club.id)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => lapsed_user.email)
      assert_difference('Membership.count', 1) do
        post :create, credit_card: { campaign_id: @campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
      end
      assert_redirected_to thank_you_checkout_path(campaign_id: @campaign.to_param, user_id: User.last.to_param)      
    end 
  end


  # #####################################################
  # # CLUBS ROLES
  # #####################################################

  test "Admin and landing roles by club should submit checkout" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      assert_difference('Prospect.count',1) do  
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id)        
        generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                     
      end
      prospect = Prospect.last
      assert_redirected_to new_checkout_path(campaign_id: @campaign.to_param, token: prospect.token)       
    end
  end

  test "Agents roles by club that should not submit checkout" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do  
        assert_difference('Prospect.count',0) do 
          prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id) 
          generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                     
        end
      end
      assert_redirected_to error_checkout_path
    end
  end

  test "Agents roles by club should not create prospect if the domain does not belong to the club" do
    @club1 = FactoryGirl.create(:simple_club_with_gateway, :checkout_url => "http://test2.host", :partner_id => @partner.id)
    @campaign1 = FactoryGirl.create(:campaign, :club_id => @club1.id, :terms_of_membership_id => @terms_of_membership.id)
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      assert_difference('Prospect.count',0) do
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club1.id)
        generate_submit_post(@campaign1.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                    
      end
      assert_redirected_to error_checkout_path(campaign_id: @campaign1.to_param)
    end
  end

  test "Agents roles by club should not create prospect if it has wrong campaign id" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      assert_difference('Prospect.count',0) do
        prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id)
        generate_submit_post(568941, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)
      end
      assert_redirected_to critical_error_checkout_path
    end
  end

  test "Agents roles by club should not create prospect if it has wrong data" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :first_name => 'M') 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)           
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"first_name"=>["is too short (minimum is 2 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :last_name => 'B') 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                 
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"last_name"=>["is too short (minimum is 2 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :first_name => 'Maarttiisswaarttiisswaarttiisswaarttiisswaarttiissweee') 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                 
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"first_name"=>["is too long (maximum is 50 characters)"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :last_name => 'Baarttiisswaarttiisswaarttiisswaarttiisswaarttiissweee') 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)                       
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"last_name"=>["is too long (maximum is 50 characters)"]})
      assert_response :redirect
      
      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :zip => 123) 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)           
      error_message = Prospect.last.error_messages  
      assert_equal( error_message, {"zip"=>["Unfortunately we are unable to ship outside of the United States at this time."]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :zip => 123451) 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)           
      error_message = Prospect.last.error_messages  
      assert_equal( error_message, {"zip"=>["Unfortunately we are unable to ship outside of the United States at this time."]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :phone_country_code => 1, :phone_area_code => 56, :phone_local_number => 456) 
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)           
      error_message = Prospect.last.error_messages        
      assert_equal( error_message, {"phone"=>["Wrong phone number"]})
      assert_response :redirect

      prospect_to_create = FactoryGirl.build(:prospect, :club_id => @club.id, :email => "alicebrennan.com")
      generate_submit_post(@campaign.to_param, prospect_to_create, @terms_of_membership.id, @agent.authentication_token)           
      error_message = Prospect.last.error_messages
      assert_equal( error_message, {"email"=>["Wrong email address"]})
      assert_response :redirect
    end
  end

  test "Admin and landing roles by club should get news" do
    ['admin', 'landing'].each do |role|
    sign_agent_with_club_role(:agent, role)
      get :new, campaign_id: @campaign.to_param, token: @prospect.token
      assert_response :success 
    end
  end

  test "admin and landing roles by club should create checkout" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id)
      assert_difference('User.count',1) do
        assert_difference('Membership.count', 1) do
          post :create, credit_card: { campaign_id: @campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
        end
      end  
      assert_redirected_to thank_you_checkout_path(campaign_id: @campaign.to_param, user_id: User.last.to_param)   
    end 
  end

  test "agents roles by club that should not create checkout" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
        perform_call_as(@agent) do
        prospect = FactoryGirl.create(:prospect, :club_id => @club.id)
        assert_difference('User.count',0) do
          assert_difference('Membership.count', 0) do
            post :create, credit_card: { campaign_id:@campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
          end
        end
        assert_redirected_to error_checkout_path
      end
    end
  end

  test "admin and landing roles by club should display duplicated_checkout" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      user = FactoryGirl.create(:active_user, :club_id => @club.id)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => user.email)
      assert_difference('User.count',0) do
        assert_difference('Membership.count', 0) do
          post :create, credit_card: { campaign_id:@campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
        end
      end      
      assert_redirected_to duplicated_checkout_path(campaign_id: @campaign.to_param, token: prospect.token)
    end 
  end

  test "agents roles by club that should not display duplicated_checkout" do
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment'].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        user = FactoryGirl.create(:active_user, :club_id => @club.id)
        prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => user.email)
        assert_difference('User.count',0) do
          assert_difference('Membership.count', 0) do
            post :create, credit_card: { campaign_id:@campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
          end
        end
        assert_redirected_to error_checkout_path
      end
    end
  end

  test "admin and landing roles by club should recover a user by checkout" do
    ['admin', 'landing'].each do |role|
      sign_agent_with_club_role(:agent, role)
      lapsed_user = FactoryGirl.create(:lapsed_user, :club_id => @club.id)
      prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :email => lapsed_user.email)
      assert_difference('Membership.count', 1) do
        post :create, credit_card: { campaign_id:@campaign.to_param, prospect_token: prospect.token, :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }  
      end
      assert_redirected_to thank_you_checkout_path(campaign_id: @campaign.to_param, user_id: User.last.to_param)
    end 
  end
end