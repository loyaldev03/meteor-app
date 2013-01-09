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

  def setup_member(create_new_member = true)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
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

  test "Profile supervisor - See full CC" do
    setup_admin
    setup_member
    @admin_agent.roles = ['supervisor']
    @admin_agent.reload

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }
    within("#table_active_credit_card")do
      wait_until{ assert page.has_content?(@saved_member.active_credit_card.number.to_s) }
    end
    within(".nav-tabs") do
      click_on("Credit Cards")
    end
    within("#credit_cards")do
      wait_until{
        assert page.has_content?(@saved_member.active_credit_card.number.to_s)
      }
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

  test "Admin should be able to destroy a credit card" do
    setup_admin
    setup_member
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within("#credit_cards")do
      wait_until{ assert page.has_selector?("#destroy") }
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

    within("#credit_cards")do
      wait_until{ assert page.has_no_selector?("#destroy") }
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

    within("#credit_cards")do
      wait_until{ assert page.has_selector?("#destroy") }
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
      fill_in 'credit_card[expire_month]', :with => credit_card.expire_month
      fill_in 'credit_card[expire_year]', :with => credit_card.expire_year
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

    within("#credit_cards")do
      wait_until{ assert page.has_no_selector?("#destroy") }
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
        assert page.has_no_content?("#{@saved_member.active_credit_card.number}") 
      }
    end

    within("#credit_cards")do
      wait_until{ 
        assert page.has_content?("#{@saved_member.active_credit_card.last_digits}")
        assert page.has_no_content?("#{@saved_member.active_credit_card.number}") 
      }
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

    within("#credit_cards")do
      wait_until{ assert page.has_selector?("#destroy") }
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
      fill_in 'credit_card[expire_month]', :with => credit_card.expire_month
      fill_in 'credit_card[expire_year]', :with => credit_card.expire_year
    }
    click_link_or_button 'Save credit card'

    credit_card = CreditCard.last
    wait_until{ page.has_content?("Credit card #{credit_card.last_digits} added and activated.") }
  end

  test "Should not be able to destroy a credit card when member was chargebacked" do
    setup_admin
    setup_member
    @saved_member.set_as_canceled!
    credit_card = FactoryGirl.create(:credit_card_american_express, :member_id => @saved_member.id, :active => false )
    FactoryGirl.create(:operation, :member_id => @saved_member.id, :operation_type => Settings.operation_types.chargeback )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find_field('input_first_name').value == @saved_member.first_name }

    within("#credit_cards")do
      wait_until{ assert page.has_no_selector?("#destroy") }
    end
  end


end