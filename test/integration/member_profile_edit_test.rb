require 'test_helper'
 
class MemberProfileEditTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(create_new_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    @club = @terms_of_membership_with_gateway.club
    @partner = @club.partner
    Time.zone = @club.time_zone
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end

    sign_in_as(@admin_agent)
   end

  test "edit member" do
    setup_member
    visit edit_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    within("#table_demographic_information") {
      assert find_field('member[first_name]').value == @saved_member.first_name
      assert find_field('member[last_name]').value == @saved_member.last_name
      assert find_field('member[city]').value == @saved_member.city
      assert find_field('member[address]').value == @saved_member.address
      assert find_field('member[zip]').value == @saved_member.zip
      assert find_field('member[state]').value == @saved_member.state
      assert find_field('member[gender]').value == @saved_member.gender
      assert find_field('member[country]').value == @saved_member.country
      assert find_field('member[birth_date]').value == "#{@saved_member.birth_date}"
    }

    within("#table_contact_information") {
      assert find_field('member[email]').value == @saved_member.email
      assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
      assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
      assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
      assert find_field('member[type_of_phone_number]').value ==  @saved_member.type_of_phone_number.to_s
    }

    alert_ok_js

    assert_difference('Member.count', 0) do 
      click_link_or_button 'Update Member'
    end
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  end


  test "set undeliverable address" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    within("#table_demographic_information") {
      assert page.has_content?("This address is undeliverable")
    }
  end

  test "add notable at classification" do
    setup_member

    visit edit_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    select('Notable', :from => 'member[member_group_type_id]')
    
    alert_ok_js

    assert_difference('Member.count', 0) do 
      click_link_or_button 'Update Member'
      sleep(5) #Wait for API response
    end
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      assert find_field('input_member_group_type').value == 'Notable' 
    }
  end


  test "add new CC and active old CC" do
    setup_member
    
    actual_member = Member.find(@saved_member.id)
    old_active_credit_card = actual_member.active_credit_card
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add a credit card'
    
    cc_number = "378282246310005"
    cc_month = Time.new.month.to_s
    cc_year = (Time.new.year + 10).to_s

    fill_in 'credit_card[number]', :with => cc_number
    fill_in 'credit_card[expire_month]', :with => cc_month
    fill_in 'credit_card[expire_year]', :with => cc_year
    
    click_on 'Save credit card'

    assert page.has_content?("Credit card #{cc_number[-4,4]} added and activated")
    
    within("#table_active_credit_card") do
      assert page.has_content?(cc_number)
      assert page.has_content?("#{cc_month} / #{cc_year}")
    end

    wait_until {
      within("#operations_table") {
          assert page.has_content?("Credit card #{cc_number[-4,4]} added and activated") 
      }
    }

    wait_until {
      within("#credit_cards") {
        within(".ligthgreen") {
          assert page.has_content?(cc_number) 
          assert page.has_content?("#{cc_month} / #{cc_year}")
          assert page.has_content?("active")
        }
      }
    }

    confirm_ok_js

    within("#credit_cards") {
      page.execute_script("window.jQuery('#new_credit_card').submit()")
    }

    wait_until {
      assert page.has_content?("Credit card #{old_active_credit_card.number.to_s[-4,4]} activated")
    }
    
    within("#credit_cards") { 
      assert page.has_content?("#{old_active_credit_card.number}") 
      assert page.has_content?("#{old_active_credit_card.expire_month} / #{old_active_credit_card.expire_year}")
    }
    
  end

  test "edit a note at operations tab" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    
    
    within("#operations_table") {
      wait_until {
        assert page.has_content?("undeliverable")
        find('.icon-zoom-in').click
      }
    }
    
    text_note = "text note 123456789"

    fill_in "operation_notes", :with => text_note
    
    assert_difference ['Operation.count'] do 
      click_on 'Save operation'
    end
    
    assert page.has_content?("Edited operation note")
    click_on 'Cancel'

    within("#operations_table") {
      wait_until {
        assert page.has_content?("Edited operation note")
        assert page.has_content?(text_note) 
      }
    }
  end

  test "edit a note and click on link" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    
    
    within("#operations_table") {
      wait_until {
        assert page.has_content?("undeliverable")
        find('.icon-zoom-in').click
      }
    }
    
    text_note = "text note 123456789"

    fill_in "operation_notes", :with => text_note
    
    assert_difference ['Operation.count'] do 
      click_on 'Save operation'
    end
    
    assert page.has_content?("Edited operation note")
    within(".alert") {
      within("p") {
        find("a").click    
      }
    }
    
    assert find_field("operation_notes").value == text_note
  
  end


  test "change unreachable phone number to reachable by check" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button "Set Unreachable"
    within("#unreachable_table"){
      select('Unreachable', :from => 'reason')
    }
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
   
   within("#table_contact_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information")do
      wait_until{
        check('setter[wrong_phone_number]')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end


  test "change unreachable address to undeliverable by check" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button "Set undeliverable"
    within("#undeliverable_table"){
      fill_in 'reason', :with => 'Undeliverable'
    }
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    within("#table_demographic_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_address, 'Undeliverable'

    click_link_or_button "Edit"
    within("#table_demographic_information")do
      wait_until{
        check('setter[wrong_address]')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable phone number to reachable by changeing phone" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    #By changing phone_country_number
    click_link_or_button "Set Unreachable"
    within("#unreachable_table"){
      select('Unreachable', :from => 'reason')
    }
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
   
    within("#table_contact_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => '9876'
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload

    assert_equal @saved_member.wrong_phone_number, nil

    #By changing phone_area_code
    click_link_or_button "Set Unreachable"
    within("#unreachable_table"){
      select('Unreachable', :from => 'reason')
    }
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
   
    within("#table_contact_information")do
     wait_until{ assert page.has_css?('tr.yellow') }
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information")do
      wait_until{ fill_in 'member[phone_area_code]', :with => '9876' }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
    #By changing phone_local_number
    click_link_or_button "Set Unreachable"
    within("#unreachable_table"){
      select('Unreachable', :from => 'reason')
    }
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
   
    within("#table_contact_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_local_number]', :with => '9876'
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end



  test "change type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.type_of_phone_number.capitalize)
      }
    end

    click_link_or_button 'Edit'

    within("#table_contact_information")do
      wait_until{
        select('Mobile', :from => 'member[type_of_phone_number]')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      @saved_member.reload  
    }
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.type_of_phone_number.capitalize)
      }
    end
  end

  test "edit member's type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.type_of_phone_number.capitalize)
      }
    end
    click_link_or_button 'Edit'
    
    within("#table_contact_information")do
      wait_until{
        select('Mobile', :from => 'member[type_of_phone_number]')
      }
    end

    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      wait_until{
        assert page.has_content?('Mobile')
      }
    end
    assert_equal Member.last.type_of_phone_number, 'mobile'
  end


  test "go from member index to edit member's phone number to a wrong phone number" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end  
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => 'TYUIYTRTYUYT'
        fill_in 'member[phone_area_code]', :with => 'TYUIYTRTYUYT'
        fill_in 'member[phone_local_number]', :with => 'TYUIYTRTYUYT'
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?('phone_country_code: is not a number')
        assert page.has_content?('phone_area_code: is not a number')
        assert page.has_content?('phone_local_number: is not a number')
      }
    end
  end

  test "go from member index to edit member's type of phone number to home type" do
    setup_member
    @saved_member.update_attribute(:type_of_phone_number, 'mobile')

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end   
    within("#table_contact_information")do
      wait_until{
        assert find_field('member[type_of_phone_number]').value == @saved_member.type_of_phone_number
        assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
        assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
        assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
        select('Home', :from => 'member[type_of_phone_number]' )
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    sleep(3)
    @saved_member.reload
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.full_phone_number)
        assert page.has_content?(@saved_member.type_of_phone_number.capitalize)
      }
    end
  end

  test "go from member index to edit member's type of phone number to other type" do
    setup_member

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end   
    within("#table_contact_information")do
      wait_until{
        assert find_field('member[type_of_phone_number]').value == @saved_member.type_of_phone_number
        assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
        assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
        assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
        select('Other', :from => 'member[type_of_phone_number]' )
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.full_phone_number)
        assert page.has_content?('Other')
      }
    end
  end


 test "go from member index to edit member's classification to VIP" do
    setup_member

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      wait_until{
        fill_in 'member[member_id]', :with => @saved_member.visible_id
        fill_in 'member[first_name]', :with => @saved_member.first_name
        fill_in 'member[last_name]', :with => @saved_member.last_name
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end   
    select('VIP', :from => 'member[member_group_type_id]')

    alert_ok_js
    click_link_or_button 'Update Member'

    assert find_field('input_member_group_type').value == 'VIP'
  end

  test "go from member index to edit member's classification to celebrity" do
    setup_member

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      wait_until{
        fill_in 'member[member_id]', :with => @saved_member.visible_id
        fill_in 'member[first_name]', :with => @saved_member.first_name
        fill_in 'member[last_name]', :with => @saved_member.last_name
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end   
    select('Celebrity', :from => 'member[member_group_type_id]')

    alert_ok_js
    click_link_or_button 'Update Member'
    
    assert find_field('input_member_group_type').value == 'Celebrity'
  end

  test "Update external id" do
    setup_member(false)
    @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
    @terms_of_membership_with_external_id = FactoryGirl.create(:terms_of_membership_with_gateway_and_external_id)

    @member_with_external_id = create_active_member(@terms_of_membership_with_external_id, :active_member_with_external_id, nil, {}, { :created_by => @admin_agent })

    visit members_path(:partner_prefix => @terms_of_membership_with_external_id.club.partner.prefix, :club_prefix => @terms_of_membership_with_external_id.club.name)
    assert_equal @club_external_id.requires_external_id, true, "Club does not have require external id"
    
    within("#payment_details")do
      wait_until{
        fill_in "member[external_id]", :with => @member_with_external_id.external_id
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        find(".icon-pencil").click
      }
    end   

    within("#external_id"){
      wait_until{
        fill_in 'member[external_id]', :with => '987654321'
      }
    }
    alert_ok_js
    click_link_or_button 'Update Member'
     wait_until{
      assert find_field('input_first_name').value == @member_with_external_id.first_name
      @member_with_external_id.reload
    }
    assert_equal @member_with_external_id.external_id, '987654321'
    within("#td_mi_external_id"){
      assert page.has_content?(@member_with_external_id.external_id)
    }
  end

  test "change member gender from male to female" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      wait_until{
        select('Female', :from => 'member[gender]')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      @saved_member.reload
    }
    wait_until{
      assert find_field('input_gender').value == ('Female')
    }
    assert_equal @saved_member.gender, 'F'
  
  end

  test "change member gender from female to male" do
    setup_member
    @saved_member.gender = 'F'
    @saved_member.save
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      wait_until{
        select('Male', :from => 'member[gender]')
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      @saved_member.reload
    }
    wait_until{
      assert find_field('input_gender').value == ('Male')
    }
    assert_equal @saved_member.gender, 'M'
  end

  #TODO: Improve test... we should validate that the 'Cancel' button is being disabled.
  test "canceled date will not be changed when it is set." do
    setup_member
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    click_link_or_button 'Cancel'
    sleep 1 
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  end

  test "Should not show destroy button on credit card when this one is the last one" do
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      wait_until { assert page.has_no_selector?("#destroy") }
    end

    @saved_member.set_as_canceled!
    @saved_member.update_attribute(:blacklisted, true)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      wait_until { assert page.has_no_selector?("#destroy") }
    end

    @saved_member.update_attribute(:blacklisted, false)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      wait_until { assert page.has_no_selector?("#destroy") }
    end
  end

  test "Delete credit card only when member is lapsed and is not blacklisted (and credit card is not the last one)" do
    setup_member
    second_credit_card = FactoryGirl.create(:credit_card_american_express , :member_id => @saved_member.id, :active => false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      wait_until { assert page.has_no_selector?("#destroy") }
    end

    @saved_member.set_as_canceled!
    @saved_member.update_attribute(:blacklisted, true)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      wait_until { assert page.has_no_selector?("#destroy") }
    end

    @saved_member.update_attribute(:blacklisted, false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")dog
      wait_until { assert page.has_selector?("#destroy") }
      confirm_ok_js
      click_link_or_button("Destroy")
    end
    wait_until{ assert page.has_content?("Credit Card #{second_credit_card.last_digits} was successfully destroyed") }
  end
end