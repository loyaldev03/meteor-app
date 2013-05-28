require 'test_helper'
 
class MemberProfileEditTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(create_new_member = true, create_member_by_sloop = false)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    @partner = @club.partner
    Time.zone = @club.time_zone
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end

    if create_member_by_sloop
      active_merchant_stubs
      unsaved_member =  FactoryGirl.build(:provisional_member_with_cc, :club_id => @club.id, :email => 'testing@withthisemail.com')
      credit_card = FactoryGirl.build(:credit_card)
      enrollment_info = FactoryGirl.build(:enrollment_info, :enrollment_amount => 0.0)

      @terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)
      create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      @saved_member = Member.find_by_email(unsaved_member.email)
    end

    sign_in_as(@admin_agent)
  end

  def set_as_unreachable_member(member,reason)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button "Set Unreachable"
    within("#unreachable_table"){
      select(reason, :from => 'reason')
    }
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
  end

  ###########################################################
  # TESTS
  ###########################################################

  # test "Add additional data to member"
  # test "Do not display Additional data section if it does not have"
  test "See Additional Member Data" do
    setup_member
    @saved_member.update_attribute(:additional_data, nil)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert page.has_no_content?("#table_additional_data")
    @saved_member.update_attribute :additional_data, {'data_field_one' => 'green','data_field_two'=> 'dodge'}
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_additional_data") do
      assert page.has_content?("data_field_one: green")
      assert page.has_content?("data_field_two: dodge")
    end
  end

  test "Bill date filter" do
    setup_member(false,false)
    unsaved_member=FactoryGirl.build(:member_with_api, :club_id => @club.id)
    unsaved_member_2=FactoryGirl.build(:member_with_api, :club_id => @club.id)
    credit_cardd=FactoryGirl.build(:credit_card_american_express)
    c = create_member(unsaved_member, credit_cardd)
    c2 = create_member(unsaved_member_2)
    tran_1 = FactoryGirl.create(:transaction, :member_id => c.id)
    tran_1.update_attribute(:created_at, Time.zone.now + 10.days)
    tran_2 = FactoryGirl.create(:transaction, :member_id => c2.id)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

    select_from_datepicker("member_billing_date_start", Time.zone.now+9.days)
    select_from_datepicker("member_billing_date_end", Time.zone.now+11.days)

    click_link_or_button('Search')
    assert page.has_content?("#{c.first_name}")
    assert page.has_no_content?("#{c2.first_name}")
  end

  test "edit member" do
    setup_member
    visit edit_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
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
    assert find_field('input_first_name').value == @saved_member.first_name
  end


  test "set undeliverable address" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    within("#table_demographic_information") {
      assert page.has_content?("This address is undeliverable")
    }
  end

  test "add notable at classification" do
    setup_member

    visit edit_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    select('Notable', :from => 'member[member_group_type_id]')

    alert_ok_js
    assert_difference('Member.count', 0) do 
      click_link_or_button 'Update Member'
      sleep 2 #Wait for API response
    end
    assert find_field('input_first_name').value == @saved_member.first_name
    assert find_field('input_member_group_type').value == 'Notable' 
  end

  test "add new CC and active old CC" do
    setup_member
    
    actual_member = Member.find(@saved_member.id)
    old_active_credit_card = actual_member.active_credit_card
    
    new_cc = FactoryGirl.build(:credit_card, :number => "378282246310005", :expire_month => Time.new.month, :expire_year => Time.new.year+10)

    last_digits = new_cc.last_digits
    add_credit_card(actual_member, new_cc)
    actual_member.reload

    cc_saved = actual_member.active_credit_card
    assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated")
    
    within("#table_active_credit_card") do
      assert page.has_content?(last_digits)
      assert page.has_content?("#{cc_saved.expire_month} / #{cc_saved.expire_year}")
    end

    within("#operations_table"){ assert page.has_content?("Credit card #{cc_saved.last_digits} added and activated") }

    within('.nav-tabs'){ click_on 'Credit Cards'}
    within("#credit_cards") {
      within(".ligthgreen") {
        assert page.has_content?(last_digits) 
        assert page.has_content?("#{cc_saved.expire_month} / #{cc_saved.expire_year}")
        assert page.has_content?("active")
      }
    }
    confirm_ok_js
    within("#credit_cards"){ click_link_or_button 'Activate' }
    
    within('.nav-tabs'){ click_on 'Credit Cards'}
    within("#credit_cards") {
      within(".ligthgreen") {
        assert page.has_content?("#{old_active_credit_card.last_digits}") 
        assert page.has_content?("#{old_active_credit_card.expire_month} / #{old_active_credit_card.expire_year}")
      }
    }
  end

  test "edit a note at operations tab" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    
    
    within("#operations_table") do
      assert page.has_content?("undeliverable")
      find('.icon-zoom-in').click
    end
    
    text_note = "text note 123456789"

    fill_in "operation_notes", :with => text_note
    
    assert_difference ['Operation.count'] do 
      click_on 'Save operation'
    end
    
    assert page.has_content?("Edited operation note")
    click_on 'Cancel'

    within("#operations_table") do
      assert page.has_content?("Edited operation note")
      assert page.has_content?(text_note) 
    end
  end

  test "edit a note and click on link" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'
    
    within("#operations_table") do
      assert page.has_content?("undeliverable")
      find('.icon-zoom-in').click
    end
    
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
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button "Set Unreachable"
    within("#unreachable_table") do
      select('Unreachable', :from => 'reason')
    end
    confirm_ok_js
    click_link_or_button 'Set wrong phone number'
   
   within("#table_contact_information")do
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information"){ check('setter[wrong_phone_number]') }
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information"){ assert !page.has_css?('tr.yellow') }
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable address to undeliverable when changeing address" do
    setup_member
    set_as_undeliverable_member(@saved_member,'reason')

    click_link_or_button "Edit"
    within("#table_demographic_information"){ fill_in 'member[address]', :with => 'another address' }
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information"){ assert !page.has_css?('tr.yellow') }
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable address to undeliverable when changeing city" do
    setup_member
    set_as_undeliverable_member(@saved_member,'reason')

    click_link_or_button "Edit"
    within("#table_demographic_information")do
      fill_in 'member[city]', :with => 'another city'
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable address to undeliverable when changeing zip" do
    setup_member
    set_as_undeliverable_member(@saved_member,'reason')

    click_link_or_button "Edit"
    within("#table_demographic_information")do
      fill_in 'member[zip]', :with => '12345'
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable address to undeliverable when changeing state" do
    setup_member
    set_as_undeliverable_member(@saved_member,'reason')

    click_link_or_button "Edit"
    within("#table_demographic_information")do
      within('#states_td'){ select('Colorado', :from => 'member[state]') }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change unreachable address to undeliverable when changeing country" do
    setup_member
    set_as_undeliverable_member(@saved_member,'reason')

    click_link_or_button "Edit"
    within("#table_demographic_information")do
      select('Canada', :from => 'member[country]')
      within('#states_td'){ select('Ontario', :from => 'member[state]') }
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
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    #By changing phone_country_number
    
    set_as_unreachable_member(@saved_member,'Unreachable')    
   
    click_link_or_button "Edit"
    within("#table_contact_information"){ fill_in 'member[phone_country_code]', :with => '9876' }
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information"){ assert !page.has_css?('tr.yellow') }
    @saved_member.reload

    assert_equal @saved_member.wrong_phone_number, nil

    #By changing phone_area_code
  
    set_as_unreachable_member(@saved_member,'Unreachable')    
  
    click_link_or_button "Edit"
    within("#table_contact_information")do
      fill_in 'member[phone_area_code]', :with => '9876'
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information"){ assert !page.has_css?('tr.yellow') }
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
    #By changing phone_local_number

    set_as_unreachable_member(@saved_member,'Unreachable')    
   
    within("#table_contact_information"){ assert page.has_css?('tr.yellow') } 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information"){ fill_in 'member[phone_local_number]', :with => '9876' }
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information"){ assert !page.has_css?('tr.yellow') }
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, nil
  end

  test "change type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    within("#table_contact_information"){ assert page.has_content?(@saved_member.type_of_phone_number.capitalize) }

    click_link_or_button 'Edit'

    within("#table_contact_information"){ select('Mobile', :from => 'member[type_of_phone_number]') }
    alert_ok_js
    click_link_or_button 'Update Member'
    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload  
    within("#table_contact_information"){ assert page.has_content?(@saved_member.type_of_phone_number.capitalize) }
  end

  test "edit member's type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    within("#table_contact_information"){ assert page.has_content?(@saved_member.type_of_phone_number.capitalize) }
    click_link_or_button 'Edit'
    
    within("#table_contact_information"){ select('Mobile', :from => 'member[type_of_phone_number]') }

    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information"){ assert page.has_content?('Mobile') }
    assert_equal Member.last.type_of_phone_number, 'mobile'
  end

  test "go from member index to edit member's phone number to a wrong phone number" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
    end
    click_link_or_button 'Search'
    within("#members"){ find(".icon-pencil").click }
    within("#table_contact_information")do
      fill_in 'member[phone_country_code]', :with => 'TYUIYTRTYUYT'
      fill_in 'member[phone_area_code]', :with => 'TYUIYTRTYUYT'
      fill_in 'member[phone_local_number]', :with => 'TYUIYTRTYUYT'
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#error_explanation")do
      assert page.has_content?('phone_country_code: is not a number')
      assert page.has_content?('phone_area_code: is not a number')
      assert page.has_content?('phone_local_number: is not a number')
    end
  end

  test "go from member index to edit member's type of phone number to home type" do
    setup_member
    @saved_member.update_attribute(:type_of_phone_number, 'mobile')

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
    end
    click_link_or_button 'Search'
    within("#members")do
      find(".icon-pencil").click
    end   
    within("#table_contact_information")do
      assert find_field('member[type_of_phone_number]').value == @saved_member.type_of_phone_number
      assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
      assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
      assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
      select('Home', :from => 'member[type_of_phone_number]' )
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    sleep(3)
    @saved_member.reload
    within("#table_contact_information")do
      assert page.has_content?(@saved_member.full_phone_number)
      assert page.has_content?(@saved_member.type_of_phone_number.capitalize)
    end
  end

  test "go from member index to edit member's type of phone number to other type" do
    setup_member

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      fill_in 'member[phone_country_code]', :with => @saved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => @saved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => @saved_member.phone_local_number
    end
    click_link_or_button 'Search'
    within("#members")do
      find(".icon-pencil").click
    end   
    within("#table_contact_information")do
      assert find_field('member[type_of_phone_number]').value == @saved_member.type_of_phone_number
      assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
      assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
      assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
      select('Other', :from => 'member[type_of_phone_number]' )
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    within("#table_contact_information")do
      assert page.has_content?(@saved_member.full_phone_number)
      assert page.has_content?('Other')
    end
  end

 test "go from member index to edit member's classification to VIP" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details") do
      fill_in 'member[id]', :with => @saved_member.id.to_s
      fill_in 'member[first_name]', :with => @saved_member.first_name
      fill_in 'member[last_name]', :with => @saved_member.last_name
    end
    click_link_or_button 'Search'
    within("#members"){ find(".icon-pencil").click }  
    select('VIP', :from => 'member[member_group_type_id]')

    alert_ok_js
    click_link_or_button 'Update Member'

    assert find_field('input_member_group_type').value == 'VIP'
  end

  test "go from member index to edit member's classification to celebrity" do
    setup_member

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      fill_in 'member[id]', :with => @saved_member.id
      fill_in 'member[first_name]', :with => @saved_member.first_name
      fill_in 'member[last_name]', :with => @saved_member.last_name
    end
    click_link_or_button 'Search'
    within("#members"){ find(".icon-pencil").click }
    select('Celebrity', :from => 'member[member_group_type_id]')

    alert_ok_js
    click_link_or_button 'Update Member'
    
    assert find_field('input_member_group_type').value == 'Celebrity'
  end

  test "Update external id" do
    setup_member(false)
    @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
    @terms_of_membership_with_external_id = FactoryGirl.create(:terms_of_membership_with_gateway_and_external_id, :club_id => @club_external_id.id)
    @member_with_external_id = create_active_member(@terms_of_membership_with_external_id, :active_member_with_external_id, nil, {}, { :created_by => @admin_agent })

    visit members_path(:partner_prefix => @terms_of_membership_with_external_id.club.partner.prefix, :club_prefix => @terms_of_membership_with_external_id.club.name)
    assert_equal @club_external_id.requires_external_id, true, "Club does not have require external id"
    
    within("#personal_details"){ fill_in "member[external_id]", :with => @member_with_external_id.external_id }
    click_link_or_button 'Search'
    within("#members"){ find(".icon-pencil").click }   

    within("#external_id"){ fill_in 'member[external_id]', :with => '987654321' }
    alert_ok_js
    click_link_or_button 'Update Member'
    assert find_field('input_first_name').value == @member_with_external_id.first_name

    @member_with_external_id.reload
    assert_equal @member_with_external_id.external_id, '987654321'
    within("#td_mi_external_id"){ assert page.has_content?(@member_with_external_id.external_id) }
  end

  test "change member gender from male to female" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information"){ select('Female', :from => 'member[gender]') }
    alert_ok_js
    click_link_or_button 'Update Member'

    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    assert find_field('input_gender').value == ('Female')
    assert_equal @saved_member.gender, 'F'
  end

  test "change member gender from female to male" do
    setup_member
    @saved_member.gender = 'F'
    @saved_member.save
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information"){ select('Male', :from => 'member[gender]') }
    alert_ok_js
    click_link_or_button 'Update Member'
    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    assert find_field('input_gender').value == ('Male')
    assert_equal @saved_member.gender, 'M'
  end

  test "Should not show destroy button on credit card when this one is the last one" do
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") } 

    @saved_member.set_as_canceled!
    @saved_member.update_attribute(:blacklisted, true)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") }

    @saved_member.update_attribute(:blacklisted, false)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") }
  end

  # Do not allow to remove credit card from members that are Blacklisted
  # Do not see Destroy button at Credit Card tab
  # Credit card 7913 added and activated.
  test "Delete credit card only when member is lapsed and is not blacklisted (and credit card is not the last one)" do
    setup_member
    second_credit_card = FactoryGirl.create(:credit_card_american_express , :member_id => @saved_member.id, :active => false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") }

    @saved_member.update_attribute(:status, "provisional")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") }

    @saved_member.set_as_canceled!
    @saved_member.update_attribute(:blacklisted, true)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards"){ assert page.has_no_selector?("#destroy") }

    @saved_member.update_attribute(:blacklisted, false)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      assert page.has_selector?("#destroy")
      confirm_ok_js
      click_link_or_button("Destroy")
    end
    wait_until{ assert page.has_content?("Credit Card #{second_credit_card.last_digits} was successfully destroyed") }
  end
  test "create a member billing enroll > 0" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
  end 

  test "create a member billing enroll > 0 + refund" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, true)
  end 

  test "create a member billing enroll = 0 provisional_days = 0 installment amount > 0" do
    active_merchant_stubs
    setup_member(false, true)
    bill_member(@saved_member, false)
  end 

  test "create a member + bill + check fultillment" do
    active_merchant_stubs
    setup_member(false)
    @product = FactoryGirl.create(:product_with_recurrent, :club_id => @club.id)

    unsaved_member =  FactoryGirl.build(:provisional_member_with_cc, :club_id => @club.id, :email => 'testing@withthisemail.com')
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info, :enrollment_amount => 0.0)
    @terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)

    @saved_member.send_fulfillment

    bill_member(@saved_member, false)

    within('.nav-tabs'){ click_on 'Fulfillments' }
    within("#fulfillments"){ assert page.has_content?("KIT-CARD") }
  end

  test "member save the sale full save" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_save_the_sale_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
     
    assert page.has_content?("Full save done")
    within("#operations_table"){ assert page.has_content?("Full save done") }
  end
 
 
  test "uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => "99999999"   
      
    click_on 'Refund'
    assert page.has_content?("Cant credit more $ than the original transaction amount")
  end

  test "two uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, true, (@terms_of_membership_with_gateway.installment_amount / 2))
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => ((@terms_of_membership_with_gateway.installment_amount / 2) + 1).to_s      
    
    assert_difference('Transaction.count', 0) do 
      click_on 'Refund'
    end
    assert page.has_content?("Cant credit more $ than the original transaction amount")
  end

  test "partial refund - uncontrolled refund" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, true, (@terms_of_membership_with_gateway.installment_amount / 2))
  end 

  test "two partial refund - uncontrolled refund" do
    active_merchant_stubs
    setup_member
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);

    bill_member(@saved_member, true, final_amount)
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => final_amount.to_s
    assert_difference('Transaction.count') do 
      click_on 'Refund'
    end
    
    within("#operations_table") do 
      wait_until {
        assert page.has_content?("Communication 'Test refund' sent")
        assert page.has_content?("Refund success $#{final_amount}")
      }
    end
  end 

  test "uncontrolled refund special characters" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => "&%$"
    alert_ok_js
    assert_difference('Transaction.count', 0) do 
      click_on 'Refund'
    end
  end

  test "Change member from Provisional (trial) status to Lapse (inactive) status" do
    setup_member
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
   
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
  end

  test "Change member from active status to lapse status" do
    setup_member
    @saved_member.set_as_active!
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
   
    within("#td_mi_next_retry_bill_date"){ wait_until{ assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) } }
  end

  test "Change member from Lapse status to Provisional statuss" do
    setup_member false, true
    @saved_member.set_as_canceled
    @terms_of_membership_with_gateway.update_attribute :provisional_days,  5
    @saved_member.recover(@terms_of_membership_with_gateway)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    @saved_member.reload 
    next_bill_date = @saved_member.current_membership.join_date + (@terms_of_membership_with_gateway.provisional_days).days
    within("#table_membership_information") do
      within("#td_mi_next_retry_bill_date") do
        assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) 
        assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) 
      end
    end
  end
  
  test "Change Next Bill Date for blank" do
    setup_member false, true
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    @saved_member.set_as_active
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    click_link_or_button 'Change'
    wait_until { page.has_content?(I18n.t('activerecord.attributes.member.next_retry_bill_date')) }

    click_link_or_button 'Change next bill date'
    wait_until{ assert page.has_content?(I18n.t('error_messages.next_bill_date_blank')) }
  end  

  test "Change Next Bill Date for tomorrow" do
    setup_member false, true
    active_merchant_stubs
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    @saved_member.set_as_active
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
   
    assert find_field('input_first_name').value == @saved_member.first_name
    
    click_link_or_button 'Change'
    page.has_content?(I18n.t('activerecord.attributes.member.next_retry_bill_date')) 
    page.execute_script("window.jQuery('#next_bill_date').next().click()")
    within("#ui-datepicker-div") do
      if ((Time.zone.now+1.day).month != Time.zone.now.month)
        within(".ui-datepicker-header"){ find(".ui-icon-circle-triangle-e").click }
      end
      click_on("#{(Time.zone.now+1.day).day}")
    end
    click_link_or_button 'Change next bill date'
    assert find_field('input_first_name').value == @saved_member.first_name
    next_bill_date = Time.zone.now + 1.day
    within("#td_mi_next_retry_bill_date"){ assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) }
  end  

  test "Next Bill Date for monthly memberships" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name 

    next_bill_date = @saved_member.join_date + eval(@terms_of_membership_with_gateway.installment_type)

    within("#td_mi_next_retry_bill_date")do
      assert page.has_no_content?(I18n.l(@saved_member.current_membership.join_date+1.month, :format => :only_date)) 
    end
  end  

  test "Successful payment." do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
  end  

  test "Provisional member" do
    setup_member(false, true)

    @saved_member.current_membership.join_date = Time.zone.now-3.day
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    within("#td_mi_status"){ assert page.has_content?("provisional") }

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-")
    end
  end 

  test "Lapsed member" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    answer = @saved_member.bill_membership
    assert (answer[:code] == Settings.error_codes.member_status_dont_allow), answer[:message]
  end 

  test "Refund from CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table_wrapper")do
      assert page.has_selector?('#refund')
      click_link_or_button("Refund")
    end
    wait_until{ fill_in 'refund_amount', :with => final_amount }
    click_link_or_button 'Refund'

    wait_until{ page.has_content?("This transaction has been approved") }

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?("Refund success $#{final_amount.to_f}")
      assert page.has_content?(I18n.l(Time.zone.now, :format => :dashed))
    end
  end 

  test "Partial refund from CS" do
    setup_member
    active_merchant_stubs
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table_wrapper")do
      assert page.has_selector?('#refund')
      click_link_or_button("Refund")
    end
    fill_in 'refund_amount', :with => final_amount
    click_link_or_button 'Refund'

    page.has_content?("This transaction has been approved")

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      wait_until{ assert page.has_content?("Refund success $#{final_amount.to_f}") }
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :dashed)) }
    end
  end 

  test "Refund a transaction with error" do
    setup_member
    active_merchant_stubs(999, message = "Error on transaccion", false)
    @terms_of_membership_with_gateway.update_attribute(:installment_amount, 45.56)
    @saved_member.active_credit_card.update_attribute(:number,'0000000000000000')


    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table"){ assert page.has_no_selector?('#refund') }
  end

  test "Billing membership amount on the Next Bill Date" do
    active_merchant_stubs
    setup_member
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

    next_bill_date = @saved_member.current_membership.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    next_bill_date_after_billing = @saved_member.bill_date + eval(@terms_of_membership_with_gateway.installment_type)

    Member.bill_all_members_up_today

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date_after_billing, :format => :only_date)) }

    within("#operations") do
      assert page.has_selector?("#operations_table")
      assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
    end

    within('.nav-tabs'){ click_on 'Transactions' }
    within("#transactions") do 
      assert page.has_selector?("#transactions_table")
      assert page.has_content?("Sale : This transaction has been approved")
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
    end

    within("#transactions_table"){ assert page.has_selector?('#refund') }
  end 

  test "See operations on CS" do
    setup_member(false, true)
    active_merchant_stubs
    @saved_member.current_membership.join_date = Time.zone.now-3.day

    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table_wrapper")do
      assert page.has_selector?('#refund')
      click_link_or_button("Refund")
    end
    fill_in 'refund_amount', :with => final_amount
    click_link_or_button 'Refund'
    wait_until{ page.has_content?("This transaction has been approved") }

    visit member_save_the_sale_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
    assert page.has_content?("Full save done")
    
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-")
      assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}")
      assert page.has_content?("Refund success $#{final_amount.to_f}")
      assert page.has_content?("Full save done")
    end
  end 

  test "Send Prebill email (7 days before NBD)" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name 
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now+7.day)
    @saved_member.update_attribute(:bill_date, Time.zone.now+7.day)

    Member.send_prebill

    sleep 2 #Wait untill script finish.
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within(".nav-tabs"){ click_on 'Communications' }
    within("#communication") do
      assert page.has_content?("Test prebill")
      assert page.has_content?("prebill")
      assert_equal(Communication.last.template_type, 'prebill')
    end
   
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Communication 'Test prebill' sent")
    end
  end

 test "Sorting transaction table" do
    setup_member

    11.times{ @saved_member.bill_membership }
    sleep 1
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table")do
      assert page.has_content?(Transaction.last.full_label.truncate(50))
      find("#th_date").click
      find("#th_date").click
      assert page.has_content?(Transaction.first.full_label.truncate(50))
    end
  end

  test "Sorting Membership table" do
    setup_member

    11.times{ @saved_member.bill_membership }
    sleep 1
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(Membership.last.id.to_s)
      find("#th_id").click
      find("#th_id").click
      assert page.has_content?(Membership.first.id.to_s)
    end
  end

  test "Update a member with CC blacklisted inside the same Club" do
    setup_member false, true
    @saved_member.active_credit_card.update_attribute :blacklisted, true 

    unsaved_member =  FactoryGirl.build(:provisional_member_with_cc, :club_id => @club.id, :email => 'testing@withthisemail.com')
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info, :enrollment_amount => 0.0)
    @terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    new_member = Member.find_by_email(unsaved_member.email)

    add_credit_card(new_member, credit_card)
    assert page.has_content?("There was an error with your credit card information. Please call member services at: #{@club.cs_phone_number}.")
    assert page.has_content?('{:number=>"Credit card is blacklisted"}')
  end
end