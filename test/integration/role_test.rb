require 'test_helper' 
 
class RolesTest < ActionController::IntegrationTest
 
  setup do
  end
  
  def setup_admin
    @agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@agent)

  end

  def setup_agent_no_rol
    @agent = FactoryGirl.create(:confirmed_agent)
    @agent.update_attribute(:roles, "")
    sign_in_as(@agent)   
  end

  def setup_supervisor
    @agent = FactoryGirl.create(:confirmed_supervisor_agent)
    sign_in_as(@agent)
  end

  def setup_representative
    @agent = FactoryGirl.create(:confirmed_representative_agent)
    @agent.update_attribute(:roles, 'representative')
    sign_in_as(@agent)
  end

  def setup_agency
    @agent = FactoryGirl.create(:confirmed_agency_agent)
    @agent.update_attribute(:roles, 'agency')
    sign_in_as(@agent)
  end

  def setup_api
    @agent = FactoryGirl.create(:confirmed_api_agent)
    @agent.update_attribute(:roles, 'api')
    sign_in_as(@agent)
  end

  def setup_fulfillment_managment
    @agent = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    @agent.update_attribute(:roles, 'fulfillment_managment')
    sign_in_as(@agent)
  end

  def setup_agent_with_club_role(club, role)
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = role
    club_role.save
    sign_in_as(@agent)
  end

  def setup_user(create_new_user = true)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_user
      @agent_admin = FactoryGirl.create(:confirmed_admin_agent)
      unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
      excecute_like_server(@club.time_zone) do 
        credit_card = FactoryGirl.build(:credit_card_master_card)
        enrollment_info = FactoryGirl.build(:enrollment_info)
        create_user_by_sloop(@agent_admin, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      end
      @saved_user = User.find_by_email(unsaved_user.email)
    end
   end


  ##############################################################
  #ADMIN
  ##############################################################

  test "select all clubs for admin agent."do
    setup_admin
    partner = FactoryGirl.create(:partner)
    10.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    find("#my_clubs").click

    within("#change_partner")do
      Club.all.each do |club|
        assert page.has_content?("#{club.partner.prefix} - #{club.name}")
      end
    end
  end

  test "Agent admin can assign role_clubs, when there are no global roles" do
    setup_admin
    setup_user false
    @agent_no_role = FactoryGirl.create :confirmed_agent
    7.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }
    club1 = Club.first
    club2 = Club.find(2)
    club3 = Club.find(3)
    club_last = Club.last
    visit edit_admin_agent_path(@agent_no_role.id)
    within(".table-condensed")do
      click_link_or_button 'Add'
      select('admin', :from => '[club_roles_attributes][1][role]')
      select(club1.name, :from => '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within(".table-condensed")do
      click_link_or_button 'Add'
      select('supervisor', :from => '[club_roles_attributes][1][role]')
      select(club2.name, :from => '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    click_link_or_button 'Edit'
    within(".table-condensed")do
      click_link_or_button 'Add'
      select('representative', :from => '[club_roles_attributes][1][role]')
      select(club3.name, :from => '[club_roles_attributes][1][club_id]')
    end
    click_link_or_button 'Update Agent'
    assert page.has_content?("admin for")
    assert page.has_content?("supervisor for")
    assert page.has_content?("representative for")
  end

  test "Admin should see full breadcrumb" do
    setup_admin
    setup_user

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".breadcrumb")do
      assert page.has_content?("Partner")
      assert page.has_content?("Club")
      assert page.has_content?("Show")
    end
  end

  test "Admin should be able to destroy a credit card" do
    setup_admin
    setup_user
    @saved_user.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      assert page.has_selector?("#destroy")
    end
  end

  test "Admin role - Recover a user" do
    setup_admin
    setup_user
    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    find(:xpath, "//a[@id='recovery']").click
    assert page.has_content?("Today in: #{@saved_user.current_membership.terms_of_membership.name}")
  end

  ##############################################################
  #SUPERVISOR
  ##############################################################

  # Select only clubs related to supervisor agent.
  test "select every club when user has global role 'supervisor'" do
    setup_supervisor
    partner = FactoryGirl.create(:partner)
    7.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    find("#my_clubs").click

    within("#change_partner")do
      Club.all.each do |club|
        assert page.has_content?("#{club.partner.prefix} - #{club.name}")
      end
    end
    within("#my_clubs_table")do
      Club.all.each {|club| assert page.has_content?(club.name) }
    end
  end

  test "Supervisor should see full breadcrumb" do
    setup_supervisor
    setup_user

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".breadcrumb")do
      assert page.has_no_content?("Partner")
      assert page.has_no_content?("Club")
      assert page.has_content?("Show")
    end
  end

  # Profile Supervisor - "Add a Credit Card" 
  test "Profile Supervisor - Add a Credit Card" do
    setup_supervisor
    setup_user
    credit_card = FactoryGirl.build(:credit_card_american_express)

    add_credit_card(@saved_user,credit_card)

    credit_card = CreditCard.last
    page.has_content?("Credit card #{credit_card.last_digits} added and activated.")
  end

  test "Profile Supervisor - Delete Credit Card" do
    setup_supervisor
    setup_user
    @saved_user.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do 
      assert page.has_selector?("#destroy")
    end
  end

  test "Mark a user as 'wrong address' - Supervisor Role" do
    setup_supervisor
    setup_user(@agent)
    5.times{FactoryGirl.create(:fulfillment, :user_id => @saved_user.id, :product_sku => 'KIT-CARD')}

    set_as_undeliverable_user(@saved_user,'reason')

    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_user.reload

    @saved_user.fulfillments do |fulfillment|
      assert_equal fulfillment.status, 'bad_address'
    end
  end

  test "Supervisor role - Recover a user" do
    setup_supervisor
    setup_user
    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    find(:xpath, "//a[@id='recovery']").click
    assert page.has_content?("Today in: #{@saved_user.current_membership.terms_of_membership.name}")
  end

  test "supervisor should be able to refund" do
    setup_supervisor
    setup_user
    
    bill_user(@saved_user, true)
  end

  ##############################################################
  # REPRESENTATIVE
  ##############################################################

  # Select only clubs related to representative agent.
  test "select every club when user has global role 'representative'" do
    setup_representative
    partner = FactoryGirl.create(:partner)
    10.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    find("#my_clubs").click

    within("#change_partner")do
      Club.all.each do |club|
        assert page.has_content?("#{club.partner.prefix} - #{club.name}")
      end
    end
  end

  test "Representative should not see full breadcrumb" do
    setup_representative
    setup_user

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".breadcrumb")do
      assert page.has_no_content?("Partner")
      assert page.has_no_content?("Club")
      assert page.has_content?("Show")
    end
  end

  #Do not allow Mark a user as "wrong address" - Representative Role
  test "Profile Representative - Delete Credit Card" do
    setup_representative
    setup_user
    @saved_user.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    assert find(:xpath, "//a[@id='link_user_set_undeliverable' and @disabled='disabled']")

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      assert page.has_no_selector?("#destroy")
    end
  end

  # Profile representative
  test "Representative should only see credit card last digits" do
    setup_representative
    setup_user
    credit_card = FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within("#table_active_credit_card") do
        assert page.has_content?("#{@saved_user.active_credit_card.last_digits}")
        assert page.has_no_content?("#{@saved_user.active_credit_card.token}")
    end

    within('.nav-tabs'){ click_on 'Credit Cards'}
    within('.tab-content') do
      within("#credit_cards") do
          assert page.has_content?("#{@saved_user.active_credit_card.last_digits}")
          assert page.has_no_content?("#{@saved_user.active_credit_card.token}")
      end
    end
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert page.has_selector?("#new_user")
  end

  # Profile Representative - "Add a Credit Card" 
  test "Profile Representative - Add a Credit Card" do
    setup_representative
    setup_user
    credit_card = FactoryGirl.build(:credit_card_american_express)

    add_credit_card(@saved_user,credit_card)

    credit_card = CreditCard.last
    page.has_content?("Credit card #{credit_card.last_digits} added and activated.")
  end

  test "Representative role - Recover a user" do
    setup_representative
    setup_user
    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    find(:xpath, "//a[@id='recovery']").click
    assert page.has_content?("Today in: #{@saved_user.current_membership.terms_of_membership.name}")
  end


   ###############################################################
   ## API
   ###############################################################

  #should show every club when api global role.
  test "Should show agent's related club_roles, when agent has api global role."do
    setup_api
    partner = FactoryGirl.create(:partner)
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }

    find("#my_clubs").click
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?("#{club.name}")
      end 
    end
    within("#change_partner")do
      Club.all.each do |club|
        assert page.has_content?("#{club.partner.prefix} - #{club.name}")
      end
    end
  end

   ###############################################################
   ## AGENCY
   ###############################################################

  # Select only clubs related to agency agent.
  test "select every club when user has global role 'agency'" do
    setup_agency
    partner = FactoryGirl.create(:partner)
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }

    find("#my_clubs").click
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?("#{club.name}")
      end
    end
    within("#change_partner")do
      Club.all.each do |club|
        assert page.has_content?("#{club.partner.prefix} - #{club.name}")
      end
    end
  end

  test "Agency should see full breadcrumb" do
    setup_agency
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within(".breadcrumb")do
      assert page.has_no_content?("Partner")
      assert page.has_no_content?("Club")
      assert page.has_content?("Show")
    end
  end

  test "Agency should not be able to destroy a credit card" do
    setup_agency
    setup_user
    credit_card = FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      assert page.has_no_selector?("#destroy")
    end
  end 

test "Agency role - Recover a user" do
    setup_agency
    setup_user
    @saved_user.set_as_canceled!

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
  end

   ###############################################################
   ## FULFILLLMENT MANAGMENT
   ###############################################################

  test "Profile fulfillment_managment" do
    setup_fulfillment_managment
    setup_user false
    unsaved_user = FactoryGirl.build(:user_with_api, :club_id => @club.id)
    create_user(unsaved_user)
    saved_user = User.find_by_email(unsaved_user.email)

    validate_view_user_base(saved_user)
  end

  test "fulfillment_managment role - Fulfillment page" do
    setup_fulfillment_managment
    setup_user

    bill_user(@saved_user, false)

    search_fulfillments
    fulfillments = []
    fulfillments << @saved_user.fulfillments.last

    #we make any update just to test...
    update_status_on_fulfillments(fulfillments, 'sent')
  end

  test "Profile fulfillment_managment - Add a Credit Card" do
    setup_fulfillment_managment
    setup_user
    @agent.update_attribute(:roles, 'fulfillment_managment')
    credit_card = FactoryGirl.build(:credit_card_american_express)

    add_credit_card(@saved_user,credit_card)

    credit_card = CreditCard.last
    page.has_content?("Credit card #{credit_card.last_digits} added and activated.")
    within("#table_active_credit_card"){
      assert page.has_content?(credit_card.last_digits)
    }
  end

  test "Profile fulfillment_managment - Refund active user" do
    setup_fulfillment_managment
    setup_user
    @agent.update_attribute(:roles, 'fulfillment_managment')
    
    bill_user(@saved_user, true)
  end

  test "fulfillment_managment role - Recover a user" do
    setup_fulfillment_managment
    setup_user
    @new_tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'new_tome')
    @saved_user.set_as_canceled!
    recover_user(@saved_user,@new_tom)
  end

   ###############################################################
   ## OTHERS
   ###############################################################

  test "Profiles that not allow see products " do
    setup_supervisor
    setup_user
    visit products_path(@club.partner.prefix, @club.name)
    assert page.has_content?("401 You are Not Authorized.")

    @agent.roles = 'representative'
    @agent.save
    visit products_path(@club.partner.prefix, @club.name)
    assert page.has_content?("401 You are Not Authorized.")

    @agent.roles = 'admin'
    @agent.save
    visit products_path(@club.partner.prefix, @club.name)
    within("#products_table_wrapper")do
      assert page.has_content?(Product.first.name)
    end
  end

  test "Should show agent's related club_roles, even when agent does not have global role."do
    setup_agent_no_rol
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @agent.add_role_with_club('representative', first_club)
    @agent.add_role_with_club('supervisor', second_club)

    find("#my_clubs").click
    within("#my_clubs_table")do
      assert page.has_content?("#{first_club.name}")
      assert page.has_content?("#{second_club.name}")
    end
  end

  test "Agents that can admin users. (without global role)" do
    setup_agent_no_rol
    partner = FactoryGirl.create(:partner)
    first_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    second_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    third_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fourth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fifth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 

    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    find("#my_clubs").click
    within("#my_clubs_table")do
      assert page.has_content?("#{first_club.name}")
      assert page.has_content?("#{second_club.name}")
      assert page.has_content?("#{third_club.name}")
      assert page.has_content?("#{fourth_club.name}")
      assert page.has_content?("#{fifth_club.name}")
    end

    visit users_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    assert page.has_selector?("#new_user")  

    visit users_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    assert page.has_selector?("#new_user")  

    visit users_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    assert page.has_content?("401 You are Not Authorized.")
    assert page.has_no_selector?("#new_user")  

    visit users_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    assert page.has_no_selector?("#new_user")  

    visit users_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    assert page.has_selector?("#new_user")  
  end

  test "Agents that can admin products. (without global role)" do
    setup_agent_no_rol
    partner = FactoryGirl.create(:partner)
    first_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    second_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    third_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fourth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fifth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 


    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    find("#my_clubs").click
    within("#my_clubs_table")do
      assert page.has_content?("#{first_club.name}")
      assert page.has_content?("#{second_club.name}")
      assert page.has_content?("#{third_club.name}")
      assert page.has_content?("#{fourth_club.name}")
      assert page.has_content?("#{fifth_club.name}")
    end

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    assert page.has_no_content?("401 You are Not Authorized.")
    assert page.has_selector?("#new_product")
    assert page.has_content?("Edit")
    assert page.has_content?("Show")
    click_link_or_button "New Product"
    assert page.has_no_content?("401 You are Not Authorized.")
    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    click_link_or_button "Edit"
    assert page.has_no_content?("401 You are Not Authorized.")


    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    assert page.has_no_content?("401 You are Not Authorized. ")
    assert page.has_selector?("#new_product")
    assert page.has_content?("Edit")
    assert page.has_content?("Show")
    click_link_or_button "New Product"
      assert page.has_no_content?("401 You are Not Authorized.")
    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    click_link_or_button "Edit"
      assert page.has_no_content?("401 You are Not Authorized.")
  end

  test "Agents that can admin fulfillments. (without global role)" do
    setup_agent_no_rol
    partner = FactoryGirl.create(:partner)
    first_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    second_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    third_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fourth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 
    fifth_club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) 

    @agent.add_role_with_club('supervisor', first_club)
    @agent.add_role_with_club('representative', second_club)
    @agent.add_role_with_club('api', third_club)
    @agent.add_role_with_club('agency', fourth_club)
    @agent.add_role_with_club('admin', fifth_club)

    find("#my_clubs").click
    within("#my_clubs_table")do
      assert page.has_content?("#{first_club.name}")
      assert page.has_content?("#{second_club.name}")
      assert page.has_content?("#{third_club.name}")
      assert page.has_content?("#{fourth_club.name}")
      assert page.has_content?("#{fifth_club.name}")
    end

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    assert page.has_content?("401 You are Not Authorized.")

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    assert page.has_no_content?("401 You are Not Authorized.")

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    assert page.has_no_content?("401 You are Not Authorized. ")
  end

  test "Should not be able to destroy a credit card when user was chargebacked" do
    setup_admin
    setup_user
    @saved_user.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, 
                                     :user_id => @saved_user.id, 
                                     :active => false )
    FactoryGirl.create(:operation, :user_id => @saved_user.id, 
                                   :operation_type => Settings.operation_types.chargeback, 
                                   :created_by_id => @agent.id )

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do 
      assert page.has_no_selector?("#destroy")
    end
  end
 
  # Admin, Supervisor, Representative and Agency role - Display Credit Card type
  test "Admin, Supervisor, fulfillment_managment, Representative and Agency role - Display Credit Card type" do
    setup_admin
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)

    assert find_field('input_first_name').value == @saved_user.first_name
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_user.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_user.active_credit_card.cc_type}")
    end

    @agent.update_attribute(:roles, 'supervisor')
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_user.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_user.active_credit_card.cc_type}")
    end

    @agent.update_attribute(:roles, 'fulfillment_managment')
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_user.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_user.active_credit_card.cc_type}")
    end 

    @agent.update_attribute(:roles, 'representative')
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_user.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_user.active_credit_card.cc_type}")
    end

    @agent.update_attribute(:roles, 'agency')
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_user.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_user.active_credit_card.cc_type}")
    end    
  end

  test "club role admin available actions" do
    setup_user false
    setup_agent_with_club_role(@club, 'admin')
    unsaved_user = FactoryGirl.build(:user_with_api, :club_id => @club.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#users")
      assert page.has_selector?("#products")
      assert page.has_selector?("#fulfillments")
      assert page.has_selector?("#fulfillment_files")
    }

    @saved_user = create_user(unsaved_user)
    FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false)
    validate_view_user_base(@saved_user)

    assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
    assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
    assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_user_note']")[:disabled] == nil
    assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
  
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_user.bill_membership
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

    @saved_user.set_as_canceled
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil }

    visit products_path(@partner.prefix, @club.name)
    assert find(:xpath, "//a[@id='new_product']")[:disabled] == nil
    within('#products_table')do
      assert find(:xpath, "//a[@id='show']")[:disabled] == nil
      assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
      assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil
    end

    visit fulfillments_index_path(@partner.prefix, @club.name)
    within('#fulfillments_table'){ assert find(:xpath, "//input[@id='make_report']")[:disabled] == nil}
  end

    test "club role representative available actions" do
      setup_user false
      setup_agent_with_club_role(@club, 'representative')
      unsaved_user = FactoryGirl.build(:user_with_api, :club_id => @club.id)

      within('#my_clubs_table'){
        assert page.has_selector?("#users")
        assert page.has_no_selector?("#products")
        assert page.has_no_selector?("#fulfillments")
        assert page.has_no_selector?("#fulfillment_files")
      }

      @saved_user = create_user(unsaved_user)
      FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false)
      validate_view_user_base(@saved_user)

      assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
      assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
      assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_user_note']")[:disabled] == nil
      assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_set_undeliverable' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
    
      @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
      active_merchant_stubs
      @saved_user.bill_membership
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      within('.nav-tabs'){click_on 'Transactions'}
      within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

      @saved_user.set_as_canceled
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert page.has_no_selector?("#destroy") }
    end

    test "club role supervisor available actions" do
      setup_user false
      setup_agent_with_club_role(@club, 'supervisor')
      unsaved_user = FactoryGirl.build(:user_with_api, :club_id => @club.id)

      within('#my_clubs_table'){
        assert page.has_selector?("#users")
        assert page.has_no_selector?("#products")
        assert page.has_no_selector?("#fulfillments")
        assert page.has_no_selector?("#fulfillment_files")
      }

      @saved_user = create_user(unsaved_user)
      FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false)
      validate_view_user_base(@saved_user)

      assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
      assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
      assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_user_note']")[:disabled] == nil
      assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
    
      @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
      active_merchant_stubs
      @saved_user.bill_membership
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      within('.nav-tabs'){click_on 'Transactions'}
      within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

      @saved_user.set_as_canceled
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil }
    end

    test "club role agency available actions" do
      setup_user
      setup_agent_with_club_role(@club, 'agency')
      FactoryGirl.create(:credit_card_american_express, :active => false ,:user_id => @saved_user.id)

      within('#my_clubs_table'){
        assert page.has_selector?("#users")
        assert page.has_selector?("#products")
        assert page.has_selector?("#fulfillments")
        assert page.has_selector?("#fulfillment_files")
      }

      visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
      assert page.has_no_selector?("#new_user")

      visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)

      assert find(:xpath, "//a[@id='edit' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='save_the_sale' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='blacklist_btn' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='add_user_note' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='cancel' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='link_user_set_undeliverable' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='link_user_set_unreachable' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='add_credit_card' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='link_user_change_next_bill_date' and @disabled='disabled']")
      assert find(:xpath, "//a[@id='link_user_add_club_cash' and @disabled='disabled']")
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button' and @disabled='disabled']") }
    
      @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
      active_merchant_stubs
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      within('.nav-tabs'){click_on 'Transactions'}
      within('#transactions_table'){ assert find(:xpath, "//a[@id='refund' and @disabled='disabled']") }

      @saved_user.set_as_canceled
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert page.has_no_selector?("#destroy") }


      visit products_path(@partner.prefix, @club.name)
      assert find(:xpath, "//a[@id='new_product']")[:disabled] == nil
      within('#products_table')do
        assert find(:xpath, "//a[@id='show']")[:disabled] == nil
        assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
        assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil
      end

      visit fulfillments_index_path(@partner.prefix, @club.name)
      within('#fulfillments_table'){ assert find(:xpath, "//input[@id='make_report']")[:disabled] == nil}
    end

    #Profile fulfillment_managment - Delete Credit Card
    test "club role fulfillment_managment available actions" do
      setup_user false
      setup_agent_with_club_role(@club, 'fulfillment_managment')
      unsaved_user = FactoryGirl.build(:user_with_api, :club_id => @club.id)

      within('#my_clubs_table'){
        assert page.has_selector?("#users")
        assert page.has_selector?("#products")
        assert page.has_selector?("#fulfillments")
        assert page.has_selector?("#fulfillment_files")
      }

      @saved_user = create_user(unsaved_user)
      FactoryGirl.create(:credit_card_american_express, :user_id => @saved_user.id, :active => false)
      validate_view_user_base(@saved_user)

      assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
      assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
      assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_user_note']")[:disabled] == nil
      assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_set_undeliverable']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_set_unreachable']")[:disabled] == nil
      assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_change_next_bill_date']")[:disabled] == nil
      assert find(:xpath, "//a[@id='link_user_add_club_cash']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
    
      @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
      active_merchant_stubs
      @saved_user.bill_membership
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      within('.nav-tabs'){click_on 'Transactions'}
      within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

      @saved_user.set_as_canceled
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
      assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
      within('.nav-tabs'){click_on 'Credit Cards'}
      within('#credit_cards'){ assert page.has_no_selector?("#destroy") }

      visit products_path(@partner.prefix, @club.name)
      assert find(:xpath, "//a[@id='new_product']")[:disabled] == nil
      within('#products_table')do
        assert find(:xpath, "//a[@id='show']")[:disabled] == nil
        assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
        assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil
      end

      visit fulfillments_index_path(@partner.prefix, @club.name)
      within('#fulfillments_table'){ assert find(:xpath, "//input[@id='make_report']")[:disabled] == nil}
    end

    test "fulfillment_managment role - Fulfillment File page" do
      setup_fulfillment_managment
      setup_user
      visit fulfillments_index_path( :partner_prefix => @partner.prefix, :club_prefix => @club.name)
    end



  test "Should see every club on my clubs table when has agency role." do
    setup_agency
    setup_user false
    
    @agent.update_attribute(:roles,'agency')
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    find("#my_clubs").click
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Users")
      assert page.has_content?("Products")
      assert page.has_content?("Fulfillments")
    end
  end

  test "Should see every club on my clubs table when has representative role." do
    setup_representative
    setup_user false

    @agent.update_attribute(:roles,'representative')
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    find("#my_clubs").click
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Users")
      assert page.has_no_content?("Products")
      assert page.has_no_content?("Fulfillments")
    end
  end

  test "Should see every club on my clubs table when has supervisor role." do
    setup_supervisor
    setup_user false
    @agent.update_attribute(:roles,'supervisor')
    5.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    find("#my_clubs").click
    within("#my_clubs_table")do
      Club.all.each do |club|
        assert page.has_content?(club.name)
        assert page.has_content?(club.id.to_s)
      end
      assert page.has_content?("Users")
      assert page.has_no_content?("Products")
      assert page.has_no_content?("Fulfillments")
    end
  end
end
