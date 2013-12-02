require 'test_helper'
 
class MembersSearchTest < ActionController::IntegrationTest

  transactions_table_empty_text = "No data available in table"
  operations_table_empty_text = "No data available in table"
  fulfillments_table_empty_text = "No fulfillments were found"
  communication_table_empty_text = "No communications were found"

  ############################################################
  # SETUP
  ############################################################

  setup do
    Member.any_instance.unstub(:solr_index)
    Member.any_instance.unstub(:solr_index!)
  end

  def setup_member(create_new_member = true)
    @default_state = "Alabama" # when we select options we do it by option text not by value ?
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, :enrollment_info, {}, { :created_by => @admin_agent })
    end

    sign_in_as(@admin_agent)
   end

  #Only for search test
  def setup_search(create_new_members = true)
    setup_member false
    if create_new_members
      20.times{ create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_member(@terms_of_membership_with_gateway, :provisional_member, nil, {}, { :created_by => @admin_agent }) }
    end
    @search_member = Member.first
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  ##########################################################
  # TESTS
  ##########################################################

  test "Do not display token field (club with auth.net) - Admin" do
    setup_member(false)
    @club.payment_gateway_configurations.first.update_attribute(:gateway, 'authorize_net')
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_no_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
     assert page.has_no_content?("#{saved_credit_card.token}")
    end
  end

  test "Do not display token field (club with auth.net) - Supervisor" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["supervisor"])
    @club.payment_gateway_configurations.first.update_attribute(:gateway, 'authorize_net')
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_no_content?("#{saved_credit_card.token}")
     end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
     assert page.has_no_content?("#{saved_credit_card.token}")
    end
  end

  test "Do not display token field (club with auth.net) - Representative" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["representative"])
    @club.payment_gateway_configurations.first.update_attribute(:gateway, 'authorize_net')
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_no_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
     assert page.has_no_content?("#{saved_credit_card.token}")
    end
  end

  test "Search members by token - Admin rol" do
    setup_member(false)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    fill_in "member[cc_token]", :with => saved_credit_card.token
    click_on 'Search'
    assert page.has_content?("#{unsaved_member.first_name}")
  end 

  test "Search members by token - Supervisor rol" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["supervisor"])
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    fill_in "member[cc_token]", :with => saved_credit_card.token
    click_on 'Search'
    assert page.has_content?("#{unsaved_member.first_name}")
  end 

    test "Search members by token - Representative rol" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["representative"])
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    end 

  test "View token in member record - Admin rol" do
    setup_member(false)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
    assert page.has_content?("#{saved_credit_card.token}")
    end
  end 

  test "View token in member record - Supervisor rol" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["supervisor"])
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
    assert page.has_content?("#{saved_credit_card.token}")
    end
  end 

  test "View token in member record - Representative rol" do
    setup_member(false)
    @admin_agent.update_attribute(:roles,["representative"])
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_member.active_credit_card
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_active_credit_card") do
      assert page.has_no_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
    assert page.has_no_content?("#{saved_credit_card.token}")
    end
  end 

  test "search members by next bill date" do
    setup_search
    @search_member.update_attribute :next_retry_bill_date, Time.zone.now.utc+7.days
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{@search_member.next_retry_bill_date.day}")
    end
    search_member("member[next_retry_bill_date]", nil, @search_member)
  end

  test "search member by member id" do
    setup_search
    search_member("member[id]", "#{@search_member.id}", @search_member)
  end

  test "search member by first name" do
    setup_search
    search_member("member[first_name]","#{@search_member.first_name}", @search_member)

  end

  test "search member with empty form" do
    setup_search 
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'Search'
    
    within("#members")do
      assert page.has_css?(".pagination")
      find("tr", :text => Member.last.full_name)
    end
  end

  # Organize Member results by Pagination
  test "search member by pagination" do
    setup_member
    20.times do  
      create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
      sleep 0.5
    end
    30.times do 
      create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, {}, { :created_by => @admin_agent }) 
      sleep 0.5
    end  
    30.times do 
      create_active_member(@terms_of_membership_with_gateway, :provisional_member, nil, {}, { :created_by => @admin_agent }) 
      sleep 0.5
    end

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'Search'
    
    within(".pagination") do
      assert page.has_content?("1")
      assert page.has_content?("2")
      assert page.has_content?("3")
      assert page.has_content?("4")      
      assert page.has_content?("Next")
    end

    within("#members")do
      begin 
        assert assert page.has_no_content?(Member.where("club_id = ?", @club.id).order("id DESC").last.full_name)
        assert page.has_content?(Member.where("club_id = ?", @club.id).order("id DESC").first.full_name)
      end
      click_on("2")
      begin 
        assert assert page.has_no_content?(Member.where("club_id = ?", @club.id).order("id DESC").last.full_name)
        assert assert page.has_content?(Member.where("club_id = ?", @club.id).order("id DESC")[40].full_name)
      end
      click_on("3")
      begin 
        assert assert page.has_no_content?(Member.where("club_id = ?", @club.id).order("id DESC").last.full_name)
        assert assert page.has_content?(Member.where("club_id = ?", @club.id).order("id DESC")[70].full_name)
      end
      click_on("4")
      begin 
        assert page.has_content?(Member.where("club_id = ?", @club.id).order("id DESC").last.full_name)
      end
    end
  end

  test "search a member with next bill date in past" do
    setup_search
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    assert page.evaluate_script("window.jQuery('.ui-datepicker-prev').is('.ui-state-disabled')")
  end

  test "display member" do
    setup_search
    search_member("member[id]", "#{@search_member.id}", @search_member)
    within("#members") do
      assert page.has_content?("#{@search_member.id}")
    end
    page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")

    validate_view_member_base(@search_member, @search_member.status)

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table") { assert page.has_content?(operations_table_empty_text) }

    active_credit_card = @search_member.active_credit_card
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on("Fulfillments") }
    within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }
    within(".nav-tabs"){ click_on("Communications") }
    within("#communication") { assert page.has_content?(communication_table_empty_text) }
  end

  #Search member with duplicated letters at Last Name
  test "search by last name" do
    setup_search false
    2.times{ create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent }) }
    2.times{ create_active_member(@terms_of_membership_with_gateway, :provisional_member, nil, {}, { :created_by => @admin_agent }) }
    2.times{ create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, {}, { :created_by => @admin_agent }) }
    create_active_member(@terms_of_membership_with_gateway, :provisional_member, nil, {}, { :created_by => @admin_agent })
  
    active_member = Member.find_by_status 'active'
    provisional_member = Member.find_by_status 'provisional'
    lapsed_member = Member.find_by_status 'lapsed'
    duplicated_name_member = Member.last
    duplicated_name_member.update_attribute(:last_name, "Elwood")

    within("#personal_details"){ fill_in "member[last_name]", :with => "Elwood" }

    click_link_or_button 'Search'
    within("#members"){ assert page.has_content?(duplicated_name_member.full_name) }

    within("#personal_details"){ fill_in "member[last_name]", :with => active_member.last_name }
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(active_member.full_name)
      assert page.has_content?(active_member.status)
      assert page.has_css?('tr td.btn-success')
    end

    within("#personal_details"){ fill_in "member[last_name]", :with => provisional_member.last_name }
    click_link_or_button 'Search'
    within("#members")do
        assert page.has_content?(provisional_member.full_name)
        assert page.has_content?(provisional_member.status)
        assert page.has_css?('tr td.btn-warning')
    end

    within("#personal_details"){ fill_in "member[last_name]", :with => lapsed_member.last_name }
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(lapsed_member.full_name)
      assert page.has_content?(lapsed_member.status)
      assert page.has_css?('tr td.btn-danger')
    end
  end

  test "search by email" do
    setup_search
    member_to_seach = Member.first

    within("#personal_details")do
      fill_in "member[email]", :with => member_to_seach.email
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "search by phone number" do
    setup_search
    member_to_seach = Member.last
    within("#personal_details")do
      fill_in "member[phone_country_code]", :with => member_to_seach.phone_country_code
      fill_in "member[phone_area_code]", :with => member_to_seach.phone_area_code
      fill_in "member[phone_local_number]", :with => member_to_seach.phone_local_number
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "search by address" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      fill_in "member[address]", :with => member_to_seach.address
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "search by city" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      fill_in "member[city]", :with => member_to_seach.city
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "search by state" do
    setup_search
    member_to_seach = Member.last
    within("#contact_details")do
      select_country_and_state(member_to_seach.country)
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "search by zip" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      fill_in "member[zip]", :with => member_to_seach.zip
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => member_to_seach.full_name)
    end
  end

  test "Searching zip with partial digits" do
    setup_search
    member_to_seach = Member.first
    member_to_seach.update_attribute(:zip, 12345)
    within("#contact_details")do
      fill_in "member[zip]", :with => "12"
    end
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(member_to_seach.full_name)
    end

    within("#contact_details")do
      fill_in "member[zip]", :with => "34"
    end
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(member_to_seach.full_name)
    end

    within("#contact_details")do
      fill_in "member[zip]", :with => "45"
    end
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(member_to_seach.full_name)
    end
  end

  test "search by last digits" do
    setup_search
    @search_member.active_credit_card.update_attribute :last_digits, 8965
    within("#payment_details")do
      fill_in "member[last_digits]", :with => @search_member.active_credit_card.last_digits
    end
    click_link_or_button 'Search'
    within("#members")do
      find("tr", :text => @search_member.full_name)
    end
  end

  test "search by notes" do
    setup_member
    member_note = FactoryGirl.create(:member_note, :member_id => @saved_member.id, 
                                     :created_by_id => @admin_agent.id,
                                     :communication_type_id => @communication_type.id,
                                     :disposition_type_id => @disposition_type.id)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#payment_details")do
        fill_in "member[notes]", :with => @saved_member.member_notes.first.description
    end
    click_link_or_button 'Search'
    within("#members")do
        assert page.has_content?(@saved_member.full_name)
    end
  end

  test "search by multiple values" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    member_note = FactoryGirl.create(:member_note, :member_id => @saved_member.id, 
                                     :created_by_id => @admin_agent.id,
                                     :communication_type_id => @communication_type.id,
                                     :disposition_type_id => @disposition_type.id)
    member_to_seach = Member.first
    within("#personal_details")do
      fill_in "member[id]", :with => @saved_member.id
      fill_in "member[first_name]", :with => @saved_member.first_name
      fill_in "member[last_name]", :with => @saved_member.last_name
      fill_in "member[email]", :with => @saved_member.email
      fill_in "member[phone_country_code]", :with => @saved_member.phone_country_code
      fill_in "member[phone_area_code]", :with => @saved_member.phone_area_code
      fill_in "member[phone_local_number]", :with => @saved_member.phone_local_number
    end
    within("#contact_details")do
      fill_in "member[city]", :with => @saved_member.city
      select_country_and_state(@saved_member.country)
      fill_in "member[address]", :with => @saved_member.address
      fill_in "member[zip]", :with => @saved_member.zip
    end
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day}")
    end
    within("#payment_details")do
      fill_in "member[last_digits]", :with => @saved_member.active_credit_card.last_digits
      fill_in "member[notes]", :with => @saved_member.member_notes.first.description
    end

    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(@saved_member.full_name)
    end
  end

  test "Trim texts when searching" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    member_note = FactoryGirl.create(:member_note, :member_id => @saved_member.id, 
                                       :created_by_id => @admin_agent.id,
                                       :communication_type_id => @communication_type.id,
                                       :disposition_type_id => @disposition_type.id)
    member_to_seach = Member.first
    within("#personal_details")do
      fill_in "member[id]", :with => " #{@saved_member.id} "
      fill_in "member[first_name]", :with => " #{@saved_member.first_name} "
      fill_in "member[last_name]", :with => " #{@saved_member.last_name} "
      fill_in "member[email]", :with => " #{@saved_member.email} "
      fill_in "member[phone_country_code]", :with => " #{@saved_member.phone_country_code} "
      fill_in "member[phone_area_code]", :with => " #{@saved_member.phone_area_code} "
      fill_in "member[phone_local_number]", :with => " #{@saved_member.phone_local_number} "
    end
    within("#contact_details")do
      fill_in "member[city]", :with => " #{@saved_member.city} "
      select_country_and_state(@saved_member.country)
      fill_in "member[address]", :with => " #{@saved_member.address} "
      fill_in "member[zip]", :with => " #{@saved_member.zip} "
    end
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day}")
    end
    within("#payment_details")do
      fill_in "member[last_digits]", :with => " #{@saved_member.active_credit_card.last_digits} "
      fill_in "member[notes]", :with => " #{@saved_member.member_notes.first.description} "
    end

    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?(@saved_member.full_name)
    end
  end

  test "search by external_id" do
    setup_member(false)    
    @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_and_external_id = FactoryGirl.create(:terms_of_membership_with_gateway_and_external_id, :club_id => @club_external_id.id)
    
    unsaved_member = FactoryGirl.build(:member_with_api)
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway_and_external_id, false)
    @member_with_external_id = Member.find_by_email unsaved_member.email     
    
    visit members_path(:partner_prefix => @member_with_external_id.club.partner.prefix, :club_prefix => @member_with_external_id.club.name)
    assert_equal @club_external_id.requires_external_id, true, "Club does not have require external id"
    within("#personal_details")do
      fill_in "member[external_id]", :with => @member_with_external_id.external_id
    end
    click_link_or_button 'Search'

    within("#members")do
      assert page.has_content?(@member_with_external_id.status)
      assert page.has_content?(@member_with_external_id.id.to_s)
      assert page.has_content?(@member_with_external_id.external_id.to_s)
      assert page.has_content?(@member_with_external_id.full_name)
      assert page.has_content?(@member_with_external_id.full_address)
    end
  end

  test "search member by invalid characters" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    member_note = FactoryGirl.create(:member_note, :member_id => @saved_member.id, 
                                     :created_by_id => @admin_agent.id,
                                     :communication_type_id => @communication_type.id,
                                     :disposition_type_id => @disposition_type.id)
    member_to_seach = Member.first
    within("#personal_details")do
      fill_in "member[id]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in "member[first_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in "member[last_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in "member[email]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
    end
    within("#contact_details")do
      fill_in "member[city]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in "member[address]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      fill_in "member[zip]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
    end
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?('No records were found.')
    end
  end

  test "search member that does not exist" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    member_note = FactoryGirl.create(:member_note, :member_id => @saved_member.id, 
                                     :created_by_id => @admin_agent.id,
                                     :communication_type_id => @communication_type.id,
                                     :disposition_type_id => @disposition_type.id)
    member_to_seach = Member.first
    within("#personal_details")do
      fill_in "member[first_name]", :with => 'Random text'
    end

    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?('No records were found.')
    end
  end

  test "search member need needs_approval" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 

    @saved_member = create_active_member(@terms_of_membership_with_gateway_needs_approval, :applied_member, :enrollment_info, {}, { :created_by => @admin_agent })

    sign_in_as(@admin_agent)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    member_to_seach = Member.first
    within("#personal_details")do
      check('member[needs_approval]')
    end
    click_link_or_button 'Search'
    within("#members")do
      assert page.has_content?("#{@saved_member.full_name}")
    end
  end

  test "should accept applied member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
        
    unsaved_member = FactoryGirl.build(:member_with_api)
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway_needs_approval, false)
    @saved_member = Member.find_by_email unsaved_member.email
    
    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    confirm_ok_js
    click_link_or_button 'Approve'
    assert find_field('input_first_name').value == @saved_member.first_name
 
    within("#table_membership_information") do  
      within("#td_mi_status") { assert page.has_content?('provisional') }
    end
    
  end

  test "should reject applied member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
    
    unsaved_member = FactoryGirl.build(:member_with_api)
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway_needs_approval, false)
    @saved_member = Member.find_by_email unsaved_member.email

    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
	
    confirm_ok_js
    click_link_or_button 'Reject'

    assert find_field('input_first_name').value == @saved_member.first_name

    @saved_member.reload
    within("#table_membership_information") do  
      within("#td_mi_status") { assert page.has_content?('lapsed') }
    end
  end

  test "create member without gender" do
    setup_member(false)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id, :gender => "")
    @saved_member = create_member(unsaved_member)
		assert find_field('input_gender').value == I18n.t('activerecord.attributes.member.no_gender')
  end

  test "create member without type of phone number" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    unsaved_member.type_of_phone_number = ''
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    create_member(unsaved_member,nil, nil, true)
    @saved_member = Member.find_by_email(unsaved_member.email)
    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    assert_equal(@saved_member.type_of_phone_number, '')
  end

  test "canceled date will be abble to be cancelled once set." do
    setup_member
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    click_link_or_button 'Cancel'
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    date = Time.zone.now + 2.day
    if (date.month > Time.zone.now.month)
      (date.month-Time.zone.now.month).times{ find(".ui-icon-circle-triangle-e").click }
    end
    within("#ui-datepicker-div") do
      click_on("#{date.day}")
    end
    select(cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_link_or_button 'Cancel member'
    
    @saved_member.reload
    assert find_field('input_first_name').value == @saved_member.first_name
    assert page.has_content?("Member cancellation scheduled to #{I18n.l(@saved_member.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}") 

    click_link_or_button 'Cancel'
    date = Time.zone.now + 3.day
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    if (date.month > Time.zone.now.month)
      (date.month-Time.zone.now.month).times{ find(".ui-icon-circle-triangle-e").click }
    end
    within("#ui-datepicker-div") do
      click_on("#{date.day}")
    end
    select(cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_link_or_button 'Cancel member'
		@saved_member.reload
    find(".alert", :text => "Member cancellation scheduled to #{I18n.l(@saved_member.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}" )
    assert page.has_content? "Member cancellation scheduled to #{I18n.l(@saved_member.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}"
  end

  # See a member is blacklisted in the search results
  test "should show status with 'Blisted' on search results, when member is blacklisted." do
    setup_member
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    @saved_member.set_as_canceled!
    @saved_member.update_attribute(:blacklisted,true)

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button 'Search'

    within("#members")do
      assert page.has_content?("- Blisted")
    end
  end
end