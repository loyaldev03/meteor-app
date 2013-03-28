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
    init_test_setup
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
    FactoryGirl.create(:batch_agent)
    
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
      20.times{ create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, {}, { :created_by => @admin_agent }) }
      20.times{ create_active_member(@terms_of_membership_with_gateway, :provisional_member, nil, {}, { :created_by => @admin_agent }) }
    end
    @search_member = Member.first
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

 #  ############################################################
 #  # UTILS
 #  ############################################################

  def fill_in_member(unsaved_member, credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select(unsaved_member.gender, :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        select_country_and_state(unsaved_member.country)
        fill_in 'member[city]', :with => unsaved_member.city
        fill_in 'member[last_name]', :with => unsaved_member.last_name
        fill_in 'member[zip]', :with => unsaved_member.zip
      }
    end
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
        select(unsaved_member.type_of_phone_number.capitalize, :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        select credit_card.expire_month.to_s, :from => 'member[credit_card][expire_month]'
        select credit_card.expire_year.to_s, :from => 'member[credit_card][expire_year]'
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'    
  end


  ###########################################################
  # TESTS
  ###########################################################

  test "search members by next bill date" do
    setup_search
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day}")
    end
    search_member("member[next_retry_bill_date]", nil, @search_member)
  end

  test "search member by member id" do
    setup_search
    search_member("member[member_id]", "#{@search_member.id}", @search_member)
  end

  test "search member by first name" do
    setup_search
    search_member("member[first_name]", "#{@search_member.first_name}", @search_member)
  end

  test "search member with empty form" do
    setup_search 
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'Search'
    
    within("#members") {
      assert page.has_css?(".pagination")
      assert page.has_content?(Member.first.full_name)
    }
  end

  test "search member by pagination" do
    setup_search
    click_on 'Search'
    
    wait_until {
      assert page.has_selector?(".pagination")
      assert page.has_content?(Member.first.full_name)
    }

    within(".pagination") do
      assert page.has_content?("1")
      assert page.has_content?("2")
      assert page.has_content?("3")
      assert page.has_content?("4")      
      assert page.has_content?("Next")
    end
    within("#members")do
      wait_until {
        if page.has_content?(Member.last.full_name)
          assert true
        else
          click_on("2")
          if page.has_content?(Member.last.full_name)
            assert true
          else
            click_on("3")
            if page.has_content?(Member.last.full_name)
              assert true
            else
              click_on("4")
              if page.has_content?(Member.last.full_name)
                assert true
              else
                assert false, "The last member was not found"
              end
            end
          end
        end
      }
    end
  end

  test "Organize Member results by Pagination" do
    setup_search
    click_on 'Search'
    wait_until {
      assert page.has_no_selector?(".pagination")
    }
    within("#members")do
      wait_until {
        assert page.has_content?(Member.find_by_id(24).full_name)
      }
    end

    wait_until {
      assert page.has_selector?(".pagination")
      assert page.has_content?(Member.first.full_name)
    }
    within("#members")do
      wait_until {
        click_on("2")
        if page.has_content?(Member.find_by_id(26).full_name)
          assert true
        else
          assert false, "The last member was not found"
        end
      }
    end

    wait_until {
      assert page.has_selector?(".pagination")
    }
    within("#members")do
      wait_until {
        click_on("3")
        if page.has_content?(Member.find_by_id(51).full_name)
          assert true
        else
          assert false, "The last member was not found"
        end
      }
    end

    wait_until {
      assert page.has_selector?(".pagination")
    }
    within("#members")do
      wait_until {
        click_on("4")
        if page.has_content?(Member.find_by_id(76).full_name)
          assert true
        else
          assert false, "The last member was not found"
        end
      }
    end
  end

  test "search a member with next bill date in past" do
    setup_search
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    assert page.evaluate_script("window.jQuery('.ui-datepicker-prev').is('.ui-state-disabled')")
  end

  
  test "display member" do
    setup_search
    search_member("member[member_id]", "#{@search_member.id}", @search_member)
    within("#members") do
      wait_until {
        assert page.has_content?("#{@search_member.id}")
      }
    end
    page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")

    validate_view_member_base(@search_member)

    within("#operations_table") { assert page.has_content?(operations_table_empty_text) }

    active_credit_card = @search_member.active_credit_card
    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }

    within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }

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
      wait_until{
        fill_in "member[email]", :with => member_to_seach.email
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by phone number" do
    setup_search
    member_to_seach = Member.first
    within("#personal_details")do
      wait_until{
        fill_in "member[phone_country_code]", :with => member_to_seach.phone_country_code
        fill_in "member[phone_area_code]", :with => member_to_seach.phone_area_code
        fill_in "member[phone_local_number]", :with => member_to_seach.phone_local_number
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by address" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      wait_until{
        fill_in "member[address]", :with => member_to_seach.address
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by city" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      wait_until{
        fill_in "member[city]", :with => member_to_seach.city
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by state" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      wait_until{
        select_country_and_state(member_to_seach.country)
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by zip" do
    setup_search
    member_to_seach = Member.first
    within("#contact_details")do
      wait_until{
        fill_in "member[zip]", :with => member_to_seach.zip
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "Searching zip with partial digits" do
    setup_search
    member_to_seach = Member.first
    member_to_seach.update_attribute(:zip, 12345)
    within("#contact_details")do
      wait_until{
        fill_in "member[zip]", :with => "12"
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end

    within("#contact_details")do
      wait_until{
        fill_in "member[zip]", :with => "34"
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end

    within("#contact_details")do
      wait_until{
        fill_in "member[zip]", :with => "45"
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
    end
  end

  test "search by last digits" do
    setup_search
    member_to_seach = Member.first
    within("#payment_details")do
      wait_until{
        fill_in "member[last_digits]", :with => member_to_seach.active_credit_card.last_digits
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(member_to_seach.full_name)
      }
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
      wait_until{
        fill_in "member[notes]", :with => @saved_member.member_notes.first.description
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(@saved_member.full_name)
      }
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
      wait_until{
        fill_in "member[member_id]", :with => @saved_member.id
        fill_in "member[first_name]", :with => @saved_member.first_name
        fill_in "member[last_name]", :with => @saved_member.last_name
        fill_in "member[email]", :with => @saved_member.email
        fill_in "member[phone_country_code]", :with => @saved_member.phone_country_code
        fill_in "member[phone_area_code]", :with => @saved_member.phone_area_code
        fill_in "member[phone_local_number]", :with => @saved_member.phone_local_number
      }
    end
    within("#contact_details")do
      wait_until{
        fill_in "member[city]", :with => @saved_member.city
        select_country_and_state(@saved_member.country)
        fill_in "member[address]", :with => @saved_member.address
        fill_in "member[zip]", :with => @saved_member.zip
      }
    end
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day}")
    end
    within("#payment_details")do
      wait_until{
        fill_in "member[last_digits]", :with => @saved_member.active_credit_card.last_digits
        fill_in "member[notes]", :with => @saved_member.member_notes.first.description
      }
    end

    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(@saved_member.full_name)
      }
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
      wait_until{
        fill_in "member[member_id]", :with => " #{@saved_member.id} "
        fill_in "member[first_name]", :with => " #{@saved_member.first_name} "
        fill_in "member[last_name]", :with => " #{@saved_member.last_name} "
        fill_in "member[email]", :with => " #{@saved_member.email} "
        fill_in "member[phone_country_code]", :with => " #{@saved_member.phone_country_code} "
        fill_in "member[phone_area_code]", :with => " #{@saved_member.phone_area_code} "
        fill_in "member[phone_local_number]", :with => " #{@saved_member.phone_local_number} "
      }
    end
    within("#contact_details")do
      wait_until{
        fill_in "member[city]", :with => " #{@saved_member.city} "
        select_country_and_state(@saved_member.country)
        fill_in "member[address]", :with => " #{@saved_member.address} "
        fill_in "member[zip]", :with => " #{@saved_member.zip} "
      }
    end
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day}")
    end
    within("#payment_details")do
      wait_until{
        fill_in "member[last_digits]", :with => " #{@saved_member.active_credit_card.last_digits} "
        fill_in "member[notes]", :with => " #{@saved_member.member_notes.first.description} "
      }
    end

    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(@saved_member.full_name)
      }
    end
  end

  test "search by external_id" do
    setup_member(false)
    @terms_of_membership_with_gateway_and_external_id = FactoryGirl.create(:terms_of_membership_with_gateway_and_external_id)
    @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
    @member_with_external_id = create_active_member(@terms_of_membership_with_gateway_and_external_id, :active_member_with_external_id, 
      nil, {}, { :created_by => @admin_agent })

    visit members_path(:partner_prefix => @member_with_external_id.club.partner.prefix, :club_prefix => @member_with_external_id.club.name)
    assert_equal @club_external_id.requires_external_id, true, "Club does not have require external id"
    within("#payment_details")do
      wait_until{
        fill_in "member[external_id]", :with => @member_with_external_id.external_id
      }
    end
    click_link_or_button 'Search'

    within("#members")do
      wait_until{
        assert page.has_content?(@member_with_external_id.status)
        assert page.has_content?(@member_with_external_id.id.to_s)
        assert page.has_content?(@member_with_external_id.external_id.to_s)
        assert page.has_content?(@member_with_external_id.full_name)
        assert page.has_content?(@member_with_external_id.full_address)
      }
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
      wait_until{
        fill_in "member[member_id]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in "member[first_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in "member[last_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in "member[email]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      }
    end
    within("#contact_details")do
      wait_until{
        fill_in "member[city]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in "member[address]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in "member[zip]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?('No records were found.')
      }
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
      wait_until{
        fill_in "member[first_name]", :with => 'Random text'
      }
    end

    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?('No records were found.')
      }
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
    within("#payment_details")do
      wait_until{
        check('member[needs_approval]')
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?("#{@saved_member.full_name}")
      }
    end
  end

  test "should accept applied member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 

    @saved_member = create_active_member(@terms_of_membership_with_gateway_needs_approval, :applied_member, :enrollment_info, {}, { :created_by => @admin_agent })

    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    confirm_ok_js
    click_link_or_button 'Approve'

    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }

    @saved_member.reload
    within("#table_membership_information") do  
      wait_until{
        within("#td_mi_status") { assert page.has_content?('provisional') }
      }
    end
  end

  test "should reject applied member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
   
    @saved_member = create_active_member(@terms_of_membership_with_gateway_needs_approval, :applied_member, :enrollment_info, {}, { :created_by => @admin_agent })

    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    confirm_ok_js
    click_link_or_button 'Reject'

    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }

    @saved_member.reload
    within("#table_membership_information") do  
      wait_until{
        within("#td_mi_status") { assert page.has_content?('lapsed') }
      }
    end
  end

  test "create member without gender" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    unsaved_member.gender = ''
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    fill_in_member(unsaved_member,credit_card)
    @saved_member = Member.find_by_email(unsaved_member.email)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      assert find_field('input_last_name').value == @saved_member.last_name
      assert find_field('input_gender').value == I18n.t('activerecord.attributes.member.no_gender')
      assert find_field('input_member_group_type').value == (@saved_member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : @saved_member.member_group_type.name)
    }
  end

  test "create member without type of phone number" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    unsaved_member.type_of_phone_number = ''
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    fill_in_member(unsaved_member,credit_card)
    @saved_member = Member.where(:first_name => unsaved_member.first_name, :last_name => unsaved_member.last_name).first
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    @saved_member.reload
    wait_until{ assert_equal(@saved_member.type_of_phone_number, '') }
  end
 
  #TODO: Improve test... we should validate that the 'Cancel' button is being disabled.
  test "canceled date will not be changed when it is set." do
    setup_member
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    click_link_or_button 'Cancel'
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.zone.now.day+1}")
    end
    select(cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_link_or_button 'Cancel member'

    @saved_member.reload
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    wait_until{ assert page.has_content?("Member cancellation scheduled to #{I18n.l(@saved_member.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}") }    
    # wait_until{ find(:xpath, "//a[@id='sync_cancel' and @disable='disable']") }

    click_link_or_button 'Cancel'
    sleep 1 
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
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
      wait_until{ assert page.has_content?("Lapsed - Blisted") }
    end
  end
end
