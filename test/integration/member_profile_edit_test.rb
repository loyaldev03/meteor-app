  require 'test_helper'
 
class MemberProfileEditTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
    @communication_type = FactoryGirl.create(:communication_type)
  end

  def setup_member(create_new_member = true, create_member_by_sloop = false)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    @partner = @club.partner
    Time.zone = @club.time_zone
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)

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

  test "edit member" do
    setup_member
    visit edit_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    within("#table_demographic_information") do
      assert find_field('member[first_name]').value == @saved_member.first_name
      assert find_field('member[last_name]').value == @saved_member.last_name
      assert find_field('member[city]').value == @saved_member.city
      assert find_field('member[address]').value == @saved_member.address
      assert find_field('member[zip]').value == @saved_member.zip
      assert find_field('member[state]').value == @saved_member.state
      assert find_field('member[gender]').value == @saved_member.gender
      assert find_field('member[country]').value == @saved_member.country
      assert find_field('member[birth_date]').value == "#{@saved_member.birth_date}"
    end

    within("#table_contact_information") do
      assert find_field('member[email]').value == @saved_member.email
      assert find_field('member[phone_country_code]').value == @saved_member.phone_country_code.to_s
      assert find_field('member[phone_area_code]').value == @saved_member.phone_area_code.to_s
      assert find_field('member[phone_local_number]').value == @saved_member.phone_local_number.to_s
      assert find_field('member[type_of_phone_number]').value ==  @saved_member.type_of_phone_number.to_s
    end

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
    
    within(".nav-tabs"){ click_on("Operations") }
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

  # edit a note at operations tab
  test "edit a note and click on link" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    click_link_or_button 'Set undeliverable'
    confirm_ok_js
    click_link_or_button 'Set wrong address'

    operation = @saved_member.operations.first
    
    within(".nav-tabs"){ click_on("Operations") }
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

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table") do
      assert page.has_content?("Edited operation note")
      assert page.has_content?(operation.id.to_s)
    end

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

  # change unreachable address to undeliverable when changeing address
  # change unreachable address to undeliverable when changeing city
  # change unreachable address to undeliverable when changeing zip
  test "change unreachable address to undeliverable when changeing address, city or zip" do
    setup_member 
    {"member[address]"=>"random address", "member[city]"=>"random city", "member[zip]"=>"98765" }.each do |field, value|
      set_as_undeliverable_member(@saved_member,'reason')

      click_link_or_button "Edit"
      within("#table_demographic_information"){ fill_in field, :with => value }
      alert_ok_js
      click_link_or_button 'Update Member'
      sleep 5
      within("#table_demographic_information"){ assert !page.has_css?('tr.yellow') }
      @saved_member.reload
      assert_equal @saved_member.wrong_phone_number, nil
    end 
  end

  # change unreachable address to undeliverable when changing country
  test "change unreachable address to undeliverable when changing state or country and state" do
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
    sleep 1
    within("#table_contact_information"){ assert page.has_content?('Mobile') }
    assert_equal Member.last.type_of_phone_number, 'mobile'
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
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club_external_id.name, :member_prefix => @member_with_external_id.id)
    assert find_field('input_first_name').value == @member_with_external_id.first_name

    @member_with_external_id.reload
    assert_equal @member_with_external_id.external_id, '987654321'
    within("#td_mi_external_id"){ assert page.has_content?(@member_with_external_id.external_id) }
  end

  # change member gender from female to male
  test "change member gender from male to female and then to male again." do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information"){ select('Female', :from => 'member[gender]') }
    alert_ok_js
    click_link_or_button 'Update Member'

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    assert find_field('input_gender').value == ('Female')
    assert_equal @saved_member.gender, 'F'

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')

    click_link_or_button 'Edit'

    within("#table_demographic_information"){ select('Male', :from => 'member[gender]') }
    alert_ok_js
    click_link_or_button 'Update Member'
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
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

    within(".nav-tabs")do
      click_on("Credit Cards")
    end 
    within("#credit_cards")do
      assert page.has_selector?("#destroy")
      confirm_ok_js
      click_link_or_button("Destroy")
    end
    assert page.has_content?("Credit Card #{second_credit_card.last_digits} was successfully destroyed")
  end

  test "member save the sale full save" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_save_the_sale_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
     
    assert page.has_content?("Full save done")
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table"){ assert page.has_content?("Full save done") }
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
    fill_in 'refunded_amount', :with => final_amount
    click_link_or_button 'Refund'
    page.has_content?("This transaction has been approved")

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

 test "Sorting transaction table" do
    setup_member
    12.times do |index| 
      FactoryGirl.create(:transaction, member_id: @saved_member.id, transaction_type: "sale", response_result: index, response_transaction_id: index, gateway: "mes")
      sleep 0.25
    end
    first_transaction = Transaction.find_by_response_result 0
    last_transaction = Transaction.find_by_response_result 11
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table")do 
      assert page.has_content?(I18n.l(last_transaction.created_at, :format => :dashed))
      find("#th_date").click
      assert page.has_content?(I18n.l(first_transaction.created_at, :format => :dashed))
    end
  end

  test "Sorting Membership table" do
    setup_member

    11.times{ @saved_member.bill_membership }
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