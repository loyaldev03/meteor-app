require "test_helper"

class PaymentGatewayConfigurationsControllerTest < ActionController::TestCase
  setup do
    @agent = FactoryBot.create(:agent)
    @admin_user = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:club, :partner_id => @partner.id)
    @simple_club_with_gateway = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
  end

  test "Admin should be able to show pgc information" do
	sign_in @admin_user
    get :show, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
    assert_response :success
  end

  test "Admin should be able to new pgc information" do
  sign_in @admin_user
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "Admin should be able to create pgc information" do
    sign_in @admin_user
    assert_difference("PaymentGatewayConfiguration.count") do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey", :login => "Login", :password => "asdasdds", :gateway => "mes" }
    end
    assert_redirected_to payment_gateway_configuration_path(assigns(:payment_gateway_configuration), partner_prefix: @partner.prefix, club_prefix: @club.name)
  end

  test "Admin should be able to edit pgc information" do
    sign_in @admin_user
    get :edit, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
    assert_response :success
  end

  test "Admin should be able to update pgc information" do
    sign_in @admin_user
    put :update, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id,
    		payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey" }
    assert_redirected_to payment_gateway_configuration_path(assigns(:payment_gateway_configuration), partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name)
  end

  test "Agents different from admin cannot get show" do
    sign_in @agent
    @agent = FactoryBot.create(:confirmed_admin_agent)
    ['supervisor', 'representative', 'fulfillment_managment', 'agency', 'api', 'landing'].each do |role|
      @agent.update_attribute :roles, role
      get :show, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
      assert_response :unauthorized
    end
  end

  test "Agents different from admin cannot get new" do
    sign_in @agent
    @agent = FactoryBot.create(:confirmed_admin_agent)
    ['supervisor', 'representative', 'fulfillment_managment', 'agency', 'api', 'landing'].each do |role|
      @agent.update_attribute :roles, role
      get :new, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name
      assert_response :unauthorized
    end
  end

  test "Agents different from admin cannot get create" do
    sign_in @agent
    @agent = FactoryBot.create(:confirmed_admin_agent)
    ['supervisor', 'representative', 'fulfillment_managment', 'agency', 'api', 'landing'].each do |role|
      @agent.update_attribute :roles, role
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey", :login => "Login", :password => "asdasdds", :gateway => "mes" }
      assert_response :unauthorized
    end
  end

  test "Agents different from admin cannot get edit" do
    sign_in @agent
    @agent = FactoryBot.create(:confirmed_admin_agent)
    ['supervisor', 'representative', 'fulfillment_managment', 'agency', 'api', 'landing'].each do |role|
      @agent.update_attribute :roles, role
      get :edit, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
      assert_response :unauthorized
    end
  end

  test "Agents different from admin cannot get update" do
    sign_in @agent
    @agent = FactoryBot.create(:confirmed_admin_agent)
    ['supervisor', 'representative', 'fulfillment_managment', 'agency', 'api', 'landing'].each do |role|
      @agent.update_attribute :roles, role
      put :update, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id,
                   payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey" }
      assert_response :unauthorized
    end
  end

  #####################################################
  # CLUBS ROLES
  ##################################################### 

  test "agent with admin club role should get show" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :show, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
    assert_response :success
  end

  test "agent with admin club role should get new" do
    sign_in(@agent)
    @club = FactoryBot.create(:club, :partner_id => @partner.id)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
    assert_response :success
  end

  test "agent with admin club role should create pgc" do
    sign_in(@agent)
    @club = FactoryBot.create(:club, :partner_id => @partner.id)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    assert_difference("PaymentGatewayConfiguration.count") do
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey", :login => "Login", :password => "asdasdds", :gateway => "mes" }
    end
    assert_redirected_to payment_gateway_configuration_path(assigns(:payment_gateway_configuration), partner_prefix: @partner.prefix, club_prefix: @club.name)
  end

  test "agent with admin club role should get edit" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    get :edit, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
    assert_response :success
  end

  test "agent with admin club role should update pgc" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    club_role.role = 'admin'
    club_role.save
    put :update, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id,
                 payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey" }
    assert_redirected_to payment_gateway_configuration_path(assigns(:payment_gateway_configuration), partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name)
  end

  test "agent with club role different from admin should not get show" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :show, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
      assert_response :unauthorized
    end
  end

  test "agent with club role different from admin should not get new" do
    sign_in(@agent)
    @club = FactoryBot.create(:club, :partner_id => @partner.id)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :new, partner_prefix: @partner.prefix, club_prefix: @club.name
      assert_response :unauthorized
    end
  end

  test "agent with club role different from admin should not get create" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @club.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey", :login => "Login", :password => "asdasdds", :gateway => "mes" }
      assert_response :unauthorized
    end
  end

  test "agent with club role different from admin should not get edit" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      get :edit, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id
      assert_response :unauthorized
    end
  end

  test "agent with club role different from admin should not get update" do
    sign_in(@agent)
    club_role = ClubRole.new :club_id => @simple_club_with_gateway.id
    club_role.agent_id = @agent.id
    ['supervisor', 'representative', 'api', 'agency', 'fulfillment_managment', 'landing'].each do |role|
      club_role.role = role
      club_role.save
      put :update, partner_prefix: @partner.prefix, club_prefix: @simple_club_with_gateway.name, id: @simple_club_with_gateway.payment_gateway_configuration.id,
                   payment_gateway_configuration: { report_group: "NewReportGroup", merchant_key: "NewMerchantKey" }
      assert_response :unauthorized
    end
  end
end