require 'test_helper' 
 
class RolesTest < ActionController::IntegrationTest
 
  def setup_admin
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    sign_in_as(@admin_agent)
  end

  def setup_supervisor
    init_test_setup
    @supervisor_agent = FactoryGirl.create(:confirmed_supervisor_agent)
    sign_in_as(@supervisor_agent)
  end

  def setup_representative
    init_test_setup
    @representative_agent = FactoryGirl.create(:confirmed_representative_agent)
    sign_in_as(@representative_agent)
  end

  def setup_agency
    init_test_setup
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    sign_in_as(@agency_agent)
  end

  def setup_agent_no_rol
    init_test_setup
    @agent = FactoryGirl.create(:confirmed_agent)
    sign_in_as(@agent)   
  end

  def setup_fulfillment_managment
    init_test_setup
    @agent = FactoryGirl.create(:confirmed_fulfillment_manager_agent)
    sign_in_as(@agent)
  end

  def setup_agent_with_club_role(club, role)
    init_test_setup
    @agent = FactoryGirl.create(:agent)
    club_role = ClubRole.new :club_id => club.id
    club_role.agent_id = @agent.id
    club_role.role = role
    club_role.save
    sign_in_as(@agent)
  end

  def setup_member(create_new_member = true)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end
   end

  test "select all clubs for admin agent."do
  	setup_admin
    partner = FactoryGirl.create(:partner)
    10.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    click_link_or_button("My Clubs")

    within("#change_partner")do
      Club.all.each do |club|
        wait_until{ assert page.has_content?("#{club.partner.prefix} - #{club.name}") }
      end
    end
  end

  # Select only clubs related to supervisor agent.
  test "select every club when member has global role 'supervisor'" do
  	setup_supervisor
    partner = FactoryGirl.create(:partner)
    7.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    click_link_or_button("My Clubs")

    within("#change_partner")do
      Club.all.each do |club|
        wait_until{ assert page.has_content?("#{club.partner.prefix} - #{club.name}") }
      end
    end
    within("#my_clubs_table")do
      Club.all.each {|club| assert page.has_content?(club.name) }
    end
  end

  # Select only clubs related to representative agent.
  test "select every club when member has global role 'representative'" do
  	setup_representative
    partner = FactoryGirl.create(:partner)
    10.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    click_link_or_button("My Clubs")

    within("#change_partner")do
      Club.all.each do |club|
        wait_until{ assert page.has_content?("#{club.partner.prefix} - #{club.name}") }
      end
    end
  end

  # Select only clubs related to agency agent.
  test "select every club when member has global role 'agency'" do
  	setup_agency
    partner = FactoryGirl.create(:partner)
    10.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    click_link_or_button("My Clubs")

    within("#change_partner")do
      Club.all.each do |club|
        wait_until{ assert page.has_content?("#{club.partner.prefix} - #{club.name}") }
      end
    end
  end

  test "Agent admin can assign role_clubs, when there are no global roles" do
    setup_admin
    setup_member false
      @agent_no_role = FactoryGirl.create :confirmed_agent
    7.times{ FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id) }

    sleep 1

    club1 = Club.first
    club2 = Club.find(2)
    club3 = Club.find(3)
    club_last = Club.last
    visit edit_admin_agent_path(@agent_no_role.id)
    within(".table-condensed")do
      select('admin', :from => 'agent[club_roles_attributes][0][role]')
      select(club1.name, :from => 'agent[club_roles_attributes][0][club_id]')
      click_link_or_button 'Add'
    end
    click_link_or_button 'Edit'
    within(".table-condensed")do
      select('supervisor', :from => 'agent[club_roles_attributes][1][role]')
      select(club2.name, :from => 'agent[club_roles_attributes][1][club_id]')
      click_link_or_button 'Add'
    end
    click_link_or_button 'Edit'
    within(".table-condensed")do
      select('representative', :from => 'agent[club_roles_attributes][2][role]')
      select(club3.name, :from => 'agent[club_roles_attributes][2][club_id]')
      click_link_or_button 'Add'
    end
    wait_until{ assert page.has_content?("admin for") }
    wait_until{ assert page.has_content?("supervisor for") }
    wait_until{ assert page.has_content?("representative for") }
  end

  test "Profiles that not allow see products " do
    setup_supervisor
    setup_member
    visit products_path(@club.partner.prefix, @club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    @supervisor_agent.roles = ['representative']
    @supervisor_agent.save
    visit products_path(@club.partner.prefix, @club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    @supervisor_agent.roles = ['admin']
    @supervisor_agent.save
    visit products_path(@club.partner.prefix, @club.name)
    within("#products_table_wrapper")do
      assert page.has_content?(Product.first.name)
    end
  end

  test "Should show agent's related club_roles, even when agent does not have global role."do
    setup_admin
    @admin_agent.roles = ['']
    @admin_agent.save
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @admin_agent.add_role_with_club('representative', first_club)
    @admin_agent.add_role_with_club('supervisor', second_club)

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      wait_until{ assert page.has_content?("#{first_club.name}") }
      wait_until{ assert page.has_content?("#{second_club.name}") }
    end
  end

  test "Should show agent's related club_roles, when agent has api global role."do
    setup_admin
    @admin_agent.roles = ['api']
    @admin_agent.save
    partner = FactoryGirl.create(:partner)
    2.times{ club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner.id) }
    first_club = Club.first
    second_club = Club.last
    @admin_agent.add_role_with_club('representative', first_club)
    @admin_agent.add_role_with_club('supervisor', second_club)

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      wait_until{ assert page.has_content?("#{first_club.name}") }
      wait_until{ assert page.has_content?("#{second_club.name}") }
    end
  end

  test "Agents that can admin members. (without global role)" do
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

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      wait_until{ assert page.has_content?("#{first_club.name}") }
      wait_until{ assert page.has_content?("#{second_club.name}") }
      wait_until{ assert page.has_content?("#{third_club.name}") }
      wait_until{ assert page.has_content?("#{fourth_club.name}") }
      wait_until{ assert page.has_content?("#{fifth_club.name}") }
    end

    visit members_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    wait_until { assert page.has_selector?("#new_member") }  

    visit members_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    wait_until { assert page.has_selector?("#new_member") }  

    visit members_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }
    wait_until { assert page.has_no_selector?("#new_member") }  

    visit members_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    wait_until { assert page.has_no_selector?("#new_member") }  

    visit members_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    wait_until { assert page.has_selector?("#new_member") }  
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

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      wait_until{ assert page.has_content?("#{first_club.name}") }
      wait_until{ assert page.has_content?("#{second_club.name}") }
      wait_until{ assert page.has_content?("#{third_club.name}") }
      wait_until{ assert page.has_content?("#{fourth_club.name}") }
      wait_until{ assert page.has_content?("#{fifth_club.name}") }
    end

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    wait_until { assert page.has_no_content?("401 You are Not Authorized.") }
    wait_until { assert page.has_selector?("#new_product") }
    wait_until { assert page.has_content?("Edit") }
    wait_until { assert page.has_content?("Show") }
    click_link_or_button "New Product"
      wait_until { assert page.has_no_content?("401 You are Not Authorized.") }
    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    click_link_or_button "Edit"
      wait_until { assert page.has_no_content?("401 You are Not Authorized.") }


    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    wait_until { assert page.has_no_content?("401 You are Not Authorized. ") }
    wait_until { assert page.has_selector?("#new_product") }
    wait_until { assert page.has_content?("Edit") }
    wait_until { assert page.has_content?("Show") }
    click_link_or_button "New Product"
      wait_until { assert page.has_no_content?("401 You are Not Authorized.") }
    visit products_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    click_link_or_button "Edit"
      wait_until { assert page.has_no_content?("401 You are Not Authorized.") }
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

    click_link_or_button("My Clubs")
    within("#my_clubs_table")do
      wait_until{ assert page.has_content?("#{first_club.name}") }
      wait_until{ assert page.has_content?("#{second_club.name}") }
      wait_until{ assert page.has_content?("#{third_club.name}") }
      wait_until{ assert page.has_content?("#{fourth_club.name}") }
      wait_until{ assert page.has_content?("#{fifth_club.name}") }
    end

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => first_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => second_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => third_club.name)
    wait_until { assert page.has_content?("401 You are Not Authorized.") }

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => fourth_club.name)
    wait_until { assert page.has_no_content?("401 You are Not Authorized.") }

    visit fulfillments_index_path( :partner_prefix => partner.prefix, :club_prefix => fifth_club.name)
    wait_until { assert page.has_no_content?("401 You are Not Authorized. ") }
  end

  test "Admin should see full breadcrumb" do
    setup_admin
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within(".breadcrumb")do
      wait_until{ assert page.has_content?("Partner") }
      wait_until{ assert page.has_content?("Club") }
      wait_until{ assert page.has_content?("Show") }
    end
  end

  test "Supervisor should see full breadcrumb" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['supervisor'])

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within(".breadcrumb")do
      wait_until{ assert page.has_no_content?("Partner") }
      wait_until{ assert page.has_no_content?("Club") }
      wait_until{ assert page.has_content?("Show") }
    end
  end

  test "Representative should not see full breadcrumb" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['representative'])

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within(".breadcrumb")do
      wait_until{ assert page.has_no_content?("Partner") }
      wait_until{ assert page.has_no_content?("Club") }
      wait_until{ assert page.has_content?("Show") }
    end
  end

  test "Agency should see full breadcrumb" do
    setup_admin
    setup_member

    @admin_agent.update_attribute(:roles, ['agency'])

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within(".breadcrumb")do
      wait_until{ assert page.has_no_content?("Partner") }
      wait_until{ assert page.has_no_content?("Club") }
      wait_until{ assert page.has_content?("Show") }
    end
  end

  test "Profile Representative - Delete Credit Card" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['representative'])
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      wait_until{ 
        wait_until{ assert page.has_no_selector?("#destroy") }
      }
    end
  end

  test "Profile Supervisor - Delete Credit Card" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['supervisor'])
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      wait_until{ 
        wait_until{ assert page.has_selector?("#destroy") }
      }
    end
  end

  # Profile Supervisor - "Add a Credit Card" 
  test "Profile Supervisor - Add a Credit Card" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['supervisor'])
    credit_card = FactoryGirl.build(:credit_card_american_express)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_active_credit_card")do
      wait_until{ assert page.has_selector?("#add_credit_card") }
      click_link_or_button("Add a credit card")
    end

    wait_until{ 
      fill_in 'credit_card[number]', :with => credit_card.number 
      select credit_card.expire_month, :from => 'credit_card[expire_month]'
      select credit_card.expire_year, :from => 'credit_card[expire_year]'
    }
    click_link_or_button 'Save credit card'

    credit_card = CreditCard.last
    wait_until{ page.has_content?("Credit card #{credit_card.last_digits} added and activated.") }
  end

  test "Agency should not be able to destroy a credit card" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['agency'])
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      wait_until{ 
        wait_until{ assert page.has_no_selector?("#destroy") }
      }
    end
  end 
  
  # Profile representative
  test "Representative should only see credit card last digits" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['representative'])
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_active_credit_card") do
      wait_until{ 
        assert page.has_content?("#{@saved_member.active_credit_card.last_digits}")
        assert page.has_no_content?("#{@saved_member.active_credit_card.token}") 
      }
    end

    within('.nav-tabs'){ click_on 'Credit Cards'}
    within('.tab-content') do
      within("#credit_cards") do
        wait_until{ 
          assert page.has_content?("#{@saved_member.active_credit_card.last_digits}")
          assert page.has_no_content?("#{@saved_member.active_credit_card.token}") 
        }
      end
    end
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    wait_until{ assert page.has_selector?("#new_member") } 
  end

  test "Admin should be able to destroy a credit card" do
    setup_admin
    setup_member
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      wait_until{ 
        wait_until{ assert page.has_selector?("#destroy") }
      }
    end
  end

  # Profile Representative - "Add a Credit Card" 
  test "Profile Representative - Add a Credit Card" do
    setup_admin
    setup_member
    @admin_agent.update_attribute(:roles, ['representative'])
    credit_card = FactoryGirl.build(:credit_card_american_express)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within("#table_active_credit_card")do
      wait_until{ assert page.has_selector?("#add_credit_card") }
      click_link_or_button("Add a credit card")
    end

    wait_until{ 
      fill_in 'credit_card[number]', :with => credit_card.number 
      select credit_card.expire_month, :from => 'credit_card[expire_month]'
      select credit_card.expire_year, :from => 'credit_card[expire_year]'
    }
    click_link_or_button 'Save credit card'

    credit_card = CreditCard.last
    wait_until{ page.has_content?("Credit card #{credit_card.last_digits} added and activated.") }
  end

  test "Should not be able to destroy a credit card when member was chargebacked" do
    setup_admin
    setup_member
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, 
                                     :member_id => @saved_member.id, 
                                     :active => false )
    FactoryGirl.create(:operation, :member_id => @saved_member.id, 
                                   :operation_type => Settings.operation_types.chargeback, 
                                   :created_by_id => @admin_agent.id )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within('.nav-tabs'){ click_on('Credit Cards')}
    within("#credit_cards") do
      wait_until{ 
        wait_until{ assert page.has_no_selector?("#destroy") }
      }
    end
  end

  test "Agency role - Recover a member" do
    setup_agency
    setup_member
    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    wait_until { assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']") }
  end

  test "Admin role - Recover a member" do
    setup_admin
    setup_member
    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    wait_until { find(:xpath, "//a[@id='recovery']").click }
    assert page.has_content?("Today in: #{@saved_member.current_membership.terms_of_membership.name}")
  end

  test "Supervisor role - Recover a member" do
    setup_supervisor
    setup_member
    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    wait_until { find(:xpath, "//a[@id='recovery']").click }
    assert page.has_content?("Today in: #{@saved_member.current_membership.terms_of_membership.name}")
  end

  test "Representative role - Recover a member" do
    setup_representative
    setup_member
    @saved_member.set_as_canceled!

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    wait_until { find(:xpath, "//a[@id='recovery']").click }
    assert page.has_content?("Today in: #{@saved_member.current_membership.terms_of_membership.name}")
  end

  test "Admin, Supervisor, fulfillment_managment, Representative and Agency role - Display Credit Card type" do
    setup_admin
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_member.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_member.active_credit_card.cc_type}")
    end

    @admin_agent.update_attribute(:roles, ['supervisor'])
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_member.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_member.active_credit_card.cc_type}")
    end

    @admin_agent.update_attribute(:roles, ['fulfillment_managment'])
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_member.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_member.active_credit_card.cc_type}")
    end 

    @admin_agent.update_attribute(:roles, ['representative'])
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_member.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_member.active_credit_card.cc_type}")
    end

    @admin_agent.update_attribute(:roles, ['agency'])
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_active_credit_card")do
      assert page.has_content?(@saved_member.active_credit_card.last_digits.to_s)
      assert page.has_content?("#{@saved_member.active_credit_card.cc_type}")
    end    
  end

  test "Profile fulfillment_managment" do
    setup_fulfillment_managment
    setup_member false
    unsaved_member = FactoryGirl.build(:member_with_api, :club_id => @club.id)
    create_member(unsaved_member)
    saved_member = Member.find_by_email(unsaved_member.email)

    validate_view_member_base(saved_member)
  end

  test "club role admin available actions" do
    setup_member false
    setup_agent_with_club_role(@club, 'admin')
    unsaved_member = FactoryGirl.build(:member_with_api, :club_id => @club.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#members")
      assert page.has_selector?("#products")
      assert page.has_selector?("#fulfillments")
      assert page.has_selector?("#fulfillment_files")
    }

    @saved_member = create_member(unsaved_member)
    FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false)
    validate_view_member_base(@saved_member)

    assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
    assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
    assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_member_note']")[:disabled] == nil
    assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_undeliverable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_unreachable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_change_next_bill_date']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_add_club_cash']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
  
    @saved_member.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    setup_member false
    setup_agent_with_club_role(@club, 'representative')
    unsaved_member = FactoryGirl.build(:member_with_api, :club_id => @club.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#members")
      assert page.has_no_selector?("#products")
      assert page.has_no_selector?("#fulfillments")
      assert page.has_no_selector?("#fulfillment_files")
    }

    @saved_member = create_member(unsaved_member)
    FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false)
    validate_view_member_base(@saved_member)

    assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
    assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
    assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_member_note']")[:disabled] == nil
    assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_undeliverable' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='link_member_set_unreachable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_change_next_bill_date']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_add_club_cash']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
  
    @saved_member.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert page.has_no_selector?("#destroy") }
  end

  test "club role supervisor available actions" do
    setup_member false
    setup_agent_with_club_role(@club, 'supervisor')
    unsaved_member = FactoryGirl.build(:member_with_api, :club_id => @club.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#members")
      assert page.has_no_selector?("#products")
      assert page.has_no_selector?("#fulfillments")
      assert page.has_no_selector?("#fulfillment_files")
    }

    @saved_member = create_member(unsaved_member)
    FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false)
    validate_view_member_base(@saved_member)

    assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
    assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
    assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_member_note']")[:disabled] == nil
    assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_undeliverable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_unreachable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_change_next_bill_date']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_add_club_cash']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
  
    @saved_member.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    assert find(:xpath, "//a[@id='recovery']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//a[@id='destroy']")[:disabled] == nil }
  end

  test "club role agency available actions" do
    setup_member
    setup_agent_with_club_role(@club, 'agency')
    FactoryGirl.create(:credit_card_american_express, :active => false ,:member_id => @saved_member.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#members")
      assert page.has_selector?("#products")
      assert page.has_selector?("#fulfillments")
      assert page.has_selector?("#fulfillment_files")
    }

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert page.has_no_selector?("#new_member")

    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.visible_id)

    assert find(:xpath, "//a[@id='edit' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='save_the_sale' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='blacklist_btn' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='add_member_note' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='cancel' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='link_member_set_undeliverable' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='link_member_set_unreachable' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='add_credit_card' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='link_member_change_next_bill_date' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='link_member_add_club_cash' and @disabled='disabled']")
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button' and @disabled='disabled']") }
  
    @saved_member.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund' and @disabled='disabled']") }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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

  test "club role fulfillment_managment available actions" do
    setup_member
    setup_agent_with_club_role(@club, 'fulfillment_managment')
    unsaved_member = FactoryGirl.build(:member_with_api, :club_id => @club.id)

    within('#my_clubs_table'){
      assert page.has_selector?("#members")
      assert page.has_selector?("#products")
      assert page.has_selector?("#fulfillments")
      assert page.has_selector?("#fulfillment_files")
    }

    @saved_member = create_member(unsaved_member)
    FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false)
    validate_view_member_base(@saved_member)

    assert find(:xpath, "//a[@id='edit']")[:disabled] == nil
    assert find(:xpath, "//a[@id='save_the_sale']")[:disabled] == nil
    assert find(:xpath, "//a[@id='blacklist_btn']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_member_note']")[:disabled] == nil
    assert find(:xpath, "//a[@id='cancel']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_undeliverable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_set_unreachable']")[:disabled] == nil
    assert find(:xpath, "//a[@id='add_credit_card']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_change_next_bill_date']")[:disabled] == nil
    assert find(:xpath, "//a[@id='link_member_add_club_cash']")[:disabled] == nil
    within('.nav-tabs'){click_on 'Credit Cards'}
    within('#credit_cards'){ assert find(:xpath, "//input[@id='activate_credit_card_button']")[:disabled] == nil }
  
    @saved_member.update_attribute :next_retry_bill_date, Time.zone.now
    active_merchant_stubs
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within('.nav-tabs'){click_on 'Transactions'}
    within('#transactions_table'){ assert find(:xpath, "//a[@id='refund']")[:disabled] == nil }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
end