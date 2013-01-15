require 'test_helper'
 
class MembersEnrollmentTest < ActionController::IntegrationTest

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
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    # @communication_type = FactoryGirl.create(:communication_type)
    # @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
   end

  def setup_email_templates
    et = EmailTemplate.new :name => "Day 7 - Trial", :client => :lyris, :template_type => :pillar_provisional
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27648, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 7
    et.save!

    et = EmailTemplate.new :name => "Day 35 - News", :client => :lyris, :template_type => :pillar_provisional
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27647, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 35
    et.save!

    et = EmailTemplate.new :name => "Day 40 - Deals", :client => :lyris, :template_type => :pillar_provisional 
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27651, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 40
    et.save!
    
    et = EmailTemplate.new :name => "Day 45 - Local Chapters", :client => :lyris, :template_type => :pillar_provisional 
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27650, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 45
    et.save!
    
    et = EmailTemplate.new :name => "Day 50 - VIP", :client => :lyris, :template_type => :pillar_provisional
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27649, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 50
    et.save!
  end

 #  ############################################################
 #  # UTILS
 #  ############################################################


  def validate_view_member_base(member, status='provisional')
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    wait_until{ assert find_field('input_first_name').value == member.first_name }

    assert find_field('input_visible_id').value == "#{member.visible_id}"
    assert find_field('input_first_name').value == member.first_name
    assert find_field('input_last_name').value == member.last_name
    assert find_field('input_gender').value == (member.gender == 'F' ? 'Female' : 'Male') unless member.gender.blank?
    assert find_field('input_member_group_type').value == (member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : member.member_group_type.name)
    
    within("#table_demographic_information") do
      assert page.has_content?(member.address)
      assert page.has_content?(member.city)
      assert page.has_content?(member.state)
      assert page.has_content?(member.country)
      assert page.has_content?(member.zip)
      assert page.has_selector?('#link_member_set_undeliverable')     
    end

    within("#table_contact_information") do
      assert page.has_content?(member.full_phone_number)
      assert page.has_content?(member.type_of_phone_number.capitalize)
      assert page.has_content?("#{member.birth_date}")
      assert page.has_selector?('#link_member_set_unreachable')     
    end

    active_credit_card = member.active_credit_card
    within("#table_active_credit_card") do
      wait_until{ assert page.has_content?("#{active_credit_card.last_digits}") }
      if active_credit_card.cc_type.nil?
        wait_until{ assert page.has_content?(I18n.t('activerecord.attributes.credit_card.type_unknown')) }
      else
        wait_until{ assert page.has_content?("#{active_credit_card.cc_type}") }
      end
      wait_until{ assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}") }
      wait_until{ assert page.has_content?(I18n.l(active_credit_card.created_at, :format => :only_date)) }
      
    end

    within("#table_membership_information") do
      
      within("#td_mi_status") { assert page.has_content?(status) }
      
      within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(member.member_since_date, :format => :only_date)) }
      
      assert page.has_content?(member.terms_of_membership.name)
      
      within("#td_mi_reactivation_times") { assert page.has_content?("#{member.reactivation_times}") }
      
      assert page.has_content?(member.current_membership.created_by.username)

      within("#td_mi_reactivation_times") { assert page.has_content?("#{member.reactivation_times}") }
      
      within("#td_mi_recycled_times") { assert page.has_content?("#{member.recycled_times}") }
      
      assert page.has_no_selector?("#td_mi_external_id")
      
      within("#td_mi_join_date") { assert page.has_content?(I18n.l(member.join_date, :format => :only_date)) }

      within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(member.next_retry_bill_date, :format => :only_date)) } if member.status != 'applied'

      assert page.has_selector?("#link_member_change_next_bill_date") if member.status != 'applied'

      within("#td_mi_club_cash_amount") { assert page.has_content?("#{member.club_cash_amount.to_f}") }

			assert page.has_selector?("#link_member_add_club_cash") if member.status == 'provisional' or member.status == 'active'

      within("#td_mi_quota") { assert page.has_content?("#{member.quota}") }      
    end  
    if not member.current_membership.enrollment_info.product_sku.blank? and not member.status == 'applied'
      within("#fulfillments") do
        assert page.has_content?('KIT') 
        assert page.has_content?('CARD') 
      end
    end
    membership = member.current_membership
    within("#memberships_table")do
      wait_until{
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(membership.quota.to_s)
        assert page.has_content?(status)
      }
    end
  end

  def validate_terms_of_membership_show_page(saved_member)
    click_link_or_button("#{saved_member.terms_of_membership.name}")
    within("#table_information")do
      wait_until{
        assert page.has_content?(@terms_of_membership_with_gateway.name) if @terms_of_membership_with_gateway.name
        assert page.has_content?(@terms_of_membership_with_gateway.description) if @terms_of_membership_with_gateway.description
        assert page.has_content?(@terms_of_membership_with_gateway.provisional_days.to_s) if @terms_of_membership_with_gateway.provisional_days
        assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s) if @terms_of_membership_with_gateway.installment_amount
        assert page.has_content?(@terms_of_membership_with_gateway.installment_type) if @terms_of_membership_with_gateway.installment_type
        assert page.has_content?(@terms_of_membership_with_gateway.grace_period.to_s) if @terms_of_membership_with_gateway.grace_period
      }
    end
    within("#table_email_template")do
      wait_until{
        EmailTemplate::TEMPLATE_TYPES.each do |type|
          assert page.has_content?("Test #{type}")
        end 
        EmailTemplate.find_all_by_terms_of_membership_id(saved_member.terms_of_membership.id).each do |et|
          assert page.has_content?(et.client)
          assert page.has_content?(et.template_type)
          assert page.has_content?(et.external_attributes.to_s)
        end 
      }
    end
  end

  def fill_in_credit_card_info(credit_card, cc_blank = false)
    if cc_blank 
      active_merchant_stubs_store("0000000000")
      within("#table_credit_card")do
        check "setter[cc_blank]"
      end
    else
      active_merchant_stubs_store(credit_card.number)
      within("#table_credit_card")do
        wait_until{
          fill_in 'member[credit_card][number]', :with => credit_card.number
          fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
          fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
        }
      end
    end
  end

  def fill_in_member(unsaved_member, credit_card = nil, approval = false, cc_blank = false)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    credit_card = FactoryGirl.build(:credit_card_master_card) if credit_card.nil?

    type_of_phone_number = (unsaved_member[:type_of_phone_number].blank? ? '' : unsaved_member.type_of_phone_number.capitalize)

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

    page.execute_script("window.jQuery('#member_birth_date').next().click()")
    within(".ui-datepicker-calendar") do
      click_on("1")
    end
    
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
        select(type_of_phone_number, :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email 
      }
    end

    if approval        
        within("#table_contact_information")do
        wait_until{
          select("test-approval", :from => 'member[terms_of_membership_id]') 
        }
      end     
    end 

    fill_in_credit_card_info(credit_card, cc_blank)

    unless unsaved_member.external_id.nil?
      fill_in 'member[external_id]', :with => unsaved_member.external_id
    end 

    alert_ok_js

    click_link_or_button 'Create Member'
  end

  def create_member(unsaved_member, credit_card = nil, approval = false, cc_blank = false)
    fill_in_member(unsaved_member,credit_card,approval,cc_blank)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    Member.find_by_email(unsaved_member.email)
  end

  def generate_operations(member)
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.enrollment_billing, :description => 'Member was enrolled' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.cancel, :description => 'Blacklisted member. Reason: Too much spam' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.save_the_sale, :description => 'Blacklisted member. Reason: dont like it' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.recovery, :description => 'Blacklisted member. Reason: testing' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.active_email, :description => 'Communication sent successfully' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'Member',
                       :member_id => member.id, :operation_type => Settings.operation_types.prebill_email, :description => 'Communication was not sent' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.others, :description => 'Member updated successfully' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => Settings.operation_types.others, :description => 'Member was recovered' )
  end

  # When creating member from web, should add KIT and CARD fulfillments 

  def validate_timezone_dates(timezone)
    @club.time_zone = timezone
    @club.save
    Time.zone = timezone
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(@saved_member.member_since_date, :format => :only_date)) }
    within("#td_mi_join_date") { assert page.has_content?(I18n.l(@saved_member.join_date, :format => :only_date)) }    
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(@saved_member.next_retry_bill_date, :format => :only_date)) }    
    within("#td_mi_credit_cards_first_created_at") { assert page.has_content?(I18n.l(@saved_member.credit_cards.first.created_at, :format => :only_date)) }    
  end

  ###########################################################
  # TESTS
  ###########################################################

  test "create member" do
  	setup_member(false)

  	unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
	  created_member = create_member(unsaved_member)

    validate_view_member_base(created_member)

    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }
    within("#table_enrollment_info") { wait_until{ assert page.has_content?( I18n.t('activerecord.attributes.member.has_no_preferences_saved')) } }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    wait_until { assert_equal(Fulfillment.count,2) }
  end

  test "Create a member with CC blank" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member,nil,false,true)

    validate_view_member_base(created_member)

    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }
  end

  # Display external_id at member search
  test "create a member inside a club with external_id in true" do
  	setup_member(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id, :external_id => "9876543210")
    created_member = create_member(unsaved_member)

    within("#td_mi_external_id") { assert page.has_content?(unsaved_member.external_id) }

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)    
    search_member("member[member_id]", "#{created_member.visible_id}", created_member)
  end

	test "new member for with external_id not requiered" do
  	setup_member(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member)
  end

  test "show dates according to club timezones" do
    setup_member
    validate_timezone_dates("Eastern Time (US & Canada)")
    validate_timezone_dates("Ekaterinburg")
  end

  test "create member without information" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_demographic_information") {
      select('United States', :from => 'member[country]')
    }
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?("first_name: can't be blank,is invalid"), "Failure on first_name validation message"
        assert page.has_content?("last_name: can't be blank,is invalid"), "Failure on last_name validation message"
        assert page.has_content?("email: can't be blank,is invalid"), "Failure on email validation message"
        assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_local_number validation message"
        assert page.has_content?("address: is invalid"), "Failure on address validation message"
        assert page.has_content?("state: can't be blank,is invalid"), "Failure on state validation message"
        assert page.has_content?("city: can't be blank,is invalid"), "Failure on city validation message"
        assert page.has_content?("zip: can't be blank,The zip code is not valid for the selected country."), "Failure on zip validation message"
      }
    end
  end

  test "create member without information and with MeS internar error" do
    setup_member
    active_merchant_stubs_store( nil, code = "999", message = "internal server error", false )

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_demographic_information") {
      select('United States', :from => 'member[country]')
    }
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?(Settings.error_messages.unrecoverable_error)
      }
    end
  end

  test "create member with invalid characters" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_demographic_information"){
      wait_until{
        fill_in 'member[first_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[address]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[city]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[last_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[zip]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        select('United States', :from => 'member[country]')
        within('#states_td'){ select('Colorado', :from => 'member[state]') }
      }
    }
    within("#table_contact_information"){
      wait_until{
        fill_in 'member[phone_country_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[phone_area_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[phone_local_number]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[email]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
      }
    }
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?("first_name: is invalid"), "Failure on first_name validation message"
        assert page.has_content?("last_name: is invalid"), "Failure on last_name validation message"
        assert page.has_content?("email: is invalid"), "Failure on email validation message"
        assert page.has_content?("phone_country_code: is not a number"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("address: is invalid"), "Failure on address validation message"
        assert page.has_content?("city: is invalid"), "Failure on city validation message"
        assert page.has_content?("zip: The zip code is not valid for the selected country."), "Failure on zip validation message"
      }
    end
  end

  test "create member with letter in phone field" do
    setup_member(false)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_contact_information"){
      wait_until{
        fill_in 'member[phone_country_code]', :with => 'werqwr'
        fill_in 'member[phone_area_code]', :with => 'werqwr'
        fill_in 'member[phone_local_number]', :with => 'werqwr'
      }
    }
    within("#table_demographic_information") {
      select('United States', :from => 'member[country]')
    }
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?("phone_country_code: is not a number"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
      }
    end
  end

  test "create member with invalid email" do
    setup_member(false)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_contact_information"){
      wait_until{
        fill_in 'member[email]', :with => 'asdfhomail.com'
      }
    }
    within("#table_demographic_information") {
      select('United States', :from => 'member[country]')
    }
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?("email: is invalid"), "Failure on email validation message"
      }
    end    
  end
  
  # return to member's profile from terms of membership
  test "show terms of membership" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    validate_terms_of_membership_show_page(@saved_member) 
    click_link_or_button('Return to member show')
    wait_until{ assert find_field('input_visible_id').value == "#{@saved_member.visible_id}" }
  end

  test "create member with gender male" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    fill_in_member(unsaved_member)

    wait_until{
      assert find_field('input_gender').value == ('Male')
    }
  end

  test "create member with gender female" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id, :gender => 'F')
    
    fill_in_member(unsaved_member)
    wait_until{ assert find_field('input_gender').value == ('Female') }
  end

  test "create member without phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id, 
                                        :phone_country_code => nil, :phone_area_code => nil, :phone_local_number => nil)

    fill_in_member(unsaved_member)

    within("#error_explanation")do
      wait_until{
        assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
      }
    end
  end

  # create member with phone number
  # create member with 'home' telephone type
  test "should create member and display type of phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id, :type_of_phone_number => 'home')
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    saved_member = create_member(unsaved_member, credit_card)
    validate_view_member_base(saved_member)
  end

  test "create member with canadian zip" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'QC',
                                         :zip => 'H3G 1M8',
                                         :country => 'Canada')
    
    saved_member = create_member(unsaved_member)
    validate_view_member_base(saved_member)
  end

  test "create member with invalid canadian zip" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'QC',
                                         :zip => '%^tYU2123',
                                         :country => 'CA')

    fill_in_member(unsaved_member)
    within('#error_explanation')do
    	wait_until{
    		assert page.has_content?('zip: The zip code is not valid for the selected country.')
    	}
  	end
  end

  test "should not let bill date to be edited" do
  	setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button 'Edit'

    assert page.has_no_selector?('member[bill_date]')
    within("#table_demographic_information")do
    	wait_until{
    		assert page.has_no_selector?('member[bill_date]')
    	}
  	end
    within("#table_contact_information")do
    	wait_until{
    		assert page.has_no_selector?('member[bill_date]')
    	}
  	end
  end

  test "display all operations on member profile" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    saved_member = create_member(unsaved_member)
    generate_operations(saved_member)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == saved_member.first_name }


    within("#operations_table")do
    	wait_until{
    		assert page.has_content?('Member was enrolled')
    		assert page.has_content?('Blacklisted member. Reason: Too much spam')
    		assert page.has_content?('Blacklisted member. Reason: dont like it')
    		assert page.has_content?('Blacklisted member. Reason: testing')
    		assert page.has_content?('Communication sent successfully')
    		assert page.has_content?('Member updated successfully')
    		assert page.has_content?('Member was recovered')
    	}
   	end
  end

  test "see operation history from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    sleep(5) #Wait for chronological difference
    10.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'Member', :member_id => @saved_member.id, 
                                :description => 'Member updated succesfully before' )
    }
    FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'Member', :member_id => @saved_member.id, 
                                :description => 'Member updated succesfully last' )

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within("#operations_table")do
      wait_until{
        assert page.has_content?('Member updated succesfully last')
      }
    end
  end

  test "see operations grouped by billing from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 100,
                                :description => 'Member enrolled - 100')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 101,
                                :description => 'Member enrolled - 101')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 103,
                                :description => 'Member enrolled - 102')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 104,
                                :description => 'Member enrolled - 103')
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#dataTableSelect")do
      wait_until{
        select('billing', :from => 'operation[operation_type]')
      }
    end

    within("#operations_table")do
      wait_until{
        assert page.has_content?('Member enrolled - 100')
        assert page.has_content?('Member enrolled - 101')
        assert page.has_content?('Member enrolled - 102')
        assert page.has_content?('Member enrolled - 103')
        assert page.has_content?('Member enrolled - 103')
      }
    end
  end

  test "see operations grouped by profile from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 200,
                                :description => 'Blacklisted member. Reason: Too much spam - 200')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 201,
                                :description => 'Blacklisted member. Reason: Too much spam - 201')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 202,
                                :description => 'Blacklisted member. Reason: Too much spam - 202')
    }
    3.times{FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 203,
                                :description => 'Blacklisted member. Reason: Too much spam - 203')
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#dataTableSelect")do
      wait_until{
        select('profile', :from => 'operation[operation_type]')
      }
    end

    within("#operations_table")do
      wait_until{
        assert page.has_content?('Blacklisted member. Reason: Too much spam - 200')
        assert page.has_content?('Blacklisted member. Reason: Too much spam - 201')
        assert page.has_content?('Blacklisted member. Reason: Too much spam - 202')
        assert page.has_content?('Blacklisted member. Reason: Too much spam - 203')
      }
    end
  end

  test "see operations grouped by communication from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    3.times{FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 300,
                                :description => 'Communication sent - 300')
    }
    3.times{FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 301,
                                :description => 'Communication sent - 301')
    }
    3.times{FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 302,
                                :description => 'Communication sent - 302')
    }
    3.times{FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 303,
                                :description => 'Communication sent - 303')
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#dataTableSelect")do
      wait_until{
        select('communications', :from => 'operation[operation_type]')
      }
    end
    within("#operations_table")do
      wait_until{
        assert page.has_content?('Communication sent - 300')
        assert page.has_content?('Communication sent - 301')
        assert page.has_content?('Communication sent - 302')
        assert page.has_content?('Communication sent - 303')
      }
    end
  end

  test "see operations grouped by others from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    10.times{FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 1000,
                                :description => 'Member was updated successfully - 1000')
    }
    FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 1000,
                                :description => 'Member was updated successfully last - 1000')
    within("#dataTableSelect")do
      wait_until{
        select('others', :from => 'operation[operation_type]')
      }
    end
    within("#operations_table")do
      wait_until{
        assert page.has_content?('Member was updated successfully last - 1000')
      }
    end
  end

  test "create a member with an expired credit card" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => 2011)
    
    fill_in_member(unsaved_member,credit_card)

    within("#error_explanation")do
      wait_until{
        assert page.has_content?(Settings.error_messages.credit_card_blank)
      }
    end
  end

  test "create blank member note" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button 'Add a note'
    click_link_or_button 'Save note'
    within("#member_notes_table") do
      wait_until{
        assert page.has_content?("Can't be blank.")
      }
    end
  end

  test "display member with blank product_sku." do
    setup_member
    @saved_member.current_membership.enrollment_info = FactoryGirl.create(:enrollment_info, :product_sku => '', :member_id => @saved_member.id)
    @saved_member.set_as_canceled!

    @saved_member.recovered

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    validate_view_member_base(@saved_member)
  end

  #Recovery time on approval members
  test "Approve member" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,true,false)
    reactivation_times = @saved_member.reactivation_times
    membership = @saved_member.current_membership

    validate_view_member_base(@saved_member,'applied')

    confirm_ok_js
    click_link_or_button 'Approve'
    wait_until{ page.has_content?("Member approved") }
    @saved_member.reload

    assert_equal reactivation_times, @saved_member.reactivation_times #did not changed

    within("#td_mi_status")do
      wait_until{ assert page.has_content?('provisional') }
    end
    within("#td_mi_join_date")do
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now+@terms_of_membership_with_approval.provisional_days.days, :format => :only_date) )}
    end
    within("#td_mi_reactivation_times")do
      wait_until{ assert page.has_content?("0")}
    end
    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      wait_until{
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(membership.quota.to_s)
        assert page.has_content?('provisional')
      }
    end

    @saved_member.set_as_canceled!
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    click_link_or_button "Recover"
    select(@terms_of_membership_with_approval.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on "Recover"

    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    within("#td_mi_reactivation_times")do
      wait_until{ assert page.has_content?("1")}
    end
  end

  test "Reject member" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,true,false)
    membership = @saved_member.current_membership

    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      wait_until{
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(membership.quota.to_s)
        assert page.has_content?('applied')
      }
    end

    confirm_ok_js
    click_link_or_button 'Reject'
    wait_until{ page.has_content?("Member was rejected and now its lapsed.") }
    @saved_member.reload

    within("#td_mi_status")do
      wait_until{ assert page.has_content?('lapsed') }
    end
    within("#td_mi_join_date")do
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
    within("#operations_table") { assert page.has_content?("Member was rejected and now its lapsed.") }

    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      wait_until{
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(membership.quota.to_s)
        assert page.has_content?('lapsed')
      }
    end
  end

  test "create member without gender" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id, :gender => '')
    @saved_member = create_member(unsaved_member)

    validate_view_member_base(@saved_member)
  end

  test "Create a member without Telephone Type" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :type_of_phone_number => '', :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    saved_member = create_member(unsaved_member)

    within("#table_contact_information")do
      wait_until{
        assert page.has_no_content?('Home')
        assert page.has_no_content?('Mobile')
        assert page.has_no_content?('Other')
      }
    end
  end

  test "Enroll a member with member approval TOM" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,true,false)
    wait_until{ page.has_selector?('#approve') }
    wait_until{ page.has_selector?('#reject') }
    validate_view_member_base(@saved_member, 'applied')

    within("#td_mi_status"){ wait_until{ assert page.has_content?('applied') }}
    within("#td_mi_join_date"){ wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }}
    within("#td_mi_next_retry_bill_date"){ wait_until{ assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) }}
    within("#operations_table") { assert page.has_content?("Member enrolled pending approval successfully $0.0 on TOM(2) -#{@terms_of_membership_with_approval.name}-") }
  end

  test "Enroll a member should create membership" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member)
    validate_view_member_base(@saved_member)
    
    membership = @saved_member.current_membership
    
  end 

  test "Update Birthday after 12 like a day" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)  


    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    click_link_or_button 'Edit'
    page.execute_script("window.jQuery('#member_birth_date').next().click()")
    sleep 1
    within(".ui-datepicker-header")do
      wait_until{ find(".ui-icon-circle-triangle-w").click }
    end
    within(".ui-datepicker-calendar") do
      wait_until{ click_on("13") }
    end    
    
    alert_ok_js
    click_link_or_button 'Update Member'
    @saved_member.reload
    within("#table_contact_information")do
      wait_until{ assert page.has_content?("#{@saved_member.birth_date}") }
    end
  end 

  #Check active email - It is send it by CS inmediate
  test "Check active email" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)  
    @saved_member.set_as_active

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    sleep 1
    within("#table_membership_information") do
      assert page.has_content?("active")
    end
    within("#communication") do
      wait_until {
        assert page.has_content?("Test active")
        assert page.has_content?("active")
        assert_equal(Communication.last.template_type, 'active')
      }
    end

    within("#operations_table") do
      wait_until {
        assert page.has_content?("Communication 'Test active' sent")
        visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    }
    end
  end

  test "Check Birthday email -  It is send it by CS at night" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member)

    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:birth_date, Time.zone.now)
    Member.send_happy_birthday
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within("#communication") do
      wait_until {
        assert page.has_content?("Test birthday")
        assert page.has_content?("birthday")
        assert_equal(Communication.last.template_type, 'birthday')
      }
    end

    within("#operations_table") do
      wait_until {
        assert page.has_content?("Communication 'Test birthday' sent")
        visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
      }
    end
  end

  def confirm_email_is_sent(amount_of_days, template_name, pillar_type, status)
    setup_member(false)
    setup_email_templates

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)  

    @saved_member.current_membership.update_attribute(:join_date, Time.zone.now-amount_of_days.day)
    Member.send_pillar_emails(pillar_type, status)
    sleep 1

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#communication") do
      wait_until {
        assert page.has_content?(template_name)
      }
    end
     within("#operations") do
      wait_until{
        select 'communications', :from => "operation[operation_type]"
      }
      wait_until{
        assert page.has_content?(template_name)
        assert page.has_no_content?("Member enrolled successfully $0.0")
        visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
      }
    end
  end

  test "Send Trial email at Day 7" do
    confirm_email_is_sent 7, "Day 7 - Trial", 'pillar_provisional', 'provisional'
  end

  test "Send News email at Day 35" do
    confirm_email_is_sent 35, "Day 35 - News", 'pillar_provisional', 'provisional'
  end

  test "Send Deals email at Day 40" do
    confirm_email_is_sent 40, "Day 40 - Deals", 'pillar_provisional', 'provisional'
  end

  test "Send Local Chapters email at Day 45" do
    confirm_email_is_sent 45, "Day 45 - Local Chapters", 'pillar_provisional', 'provisional'
  end

  test "Send VIP email at Day 50" do
    confirm_email_is_sent 50, "Day 50 - VIP", 'pillar_provisional', 'provisional'
  end

  test "Filtering by Communication at Operations tab" do
    setup_member(false)
    setup_email_templates

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_member = Member.find_by_email(unsaved_member.email)  

    Settings.operation_types.collect do |key,value| 
      FactoryGirl.create(:operation, :description => key, :operation_type => value, :member_id => created_member.id, :created_by_id => @admin_agent)
    end

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => created_member.visible_id)
    within("#operations") do
      wait_until{
        select 'communications', :from => "operation[operation_type]"
      }
      wait_until{
        assert page.has_no_content?('enrollment_billing')        
        assert page.has_no_content?('save_the_sale')        
        assert page.has_content?('prebill_email')        
        assert page.has_content?('cancellation_email')        
        assert page.has_content?('refund_email')        
        assert page.has_no_content?('credit_card_in_use')        
      }
    end

    within("#operations") do
      wait_until{
        select 'billing', :from => "operation[operation_type]"
      }
      wait_until{

        assert page.has_content?('enrollment_billing')        
        assert page.has_content?('membership_billing')        
        assert page.has_content?('full_save')        
        assert page.has_no_content?('save_the_sale')        
        assert page.has_no_content?('prebill_email')        
        assert page.has_no_content?('credit_card_in_use')        
      }
    end    
  
    within("#operations") do
      wait_until{
        select 'profile', :from => "operation[operation_type]"
      }
      wait_until{

        assert page.has_no_content?('enrollment_billing')        
        assert page.has_content?('fulfillment_mannualy_mark_as_sent')        
        assert page.has_content?('blacklisted')        
        assert page.has_content?('deducted_club_cash')        
        assert page.has_no_content?('prebill_email')        
        assert page.has_no_content?('credit_card_in_use')        
      }
    end    

    within("#operations") do
      wait_until{
        select 'others', :from => "operation[operation_type]"
      }
      wait_until{
        assert page.has_no_content?('enrollment_billing')        
        assert page.has_no_content?('cancel')        
        assert page.has_no_content?('prebill_email')        
        assert page.has_no_content?('credit_card_in_use')        
        assert page.has_content?('others')           
      }
    end    
  end
end

  