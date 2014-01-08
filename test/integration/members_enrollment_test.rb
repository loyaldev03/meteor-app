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
  end

  def setup_member(create_new_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner

    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    # @communication_type = FactoryGirl.create(:communication_type)
    # @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
  end

  def setup_email_templates
    et = EmailTemplate.new :name => "Day 7 - Trial", :client => :lyris, :template_type => :pillar
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27648, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 7
    et.save!

    et = EmailTemplate.new :name => "Day 35 - News", :client => :lyris, :template_type => :pillar
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27647, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 35
    et.save!

    et = EmailTemplate.new :name => "Day 40 - Deals", :client => :lyris, :template_type => :pillar
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27651, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 40
    et.save!
    
    et = EmailTemplate.new :name => "Day 45 - Local Chapters", :client => :lyris, :template_type => :pillar
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27650, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 45
    et.save!
    
    et = EmailTemplate.new :name => "Day 50 - VIP", :client => :lyris, :template_type => :pillar
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27649, :mlid => 226095, :site_id => 123 }
    et.days_after_join_date = 50
    et.save!
  end

 #  ############################################################
 #  # UTILS
 #  ############################################################

  def validate_terms_of_membership_show_page(saved_member)
    within("#table_membership_information")do
      within("#td_mi_terms_of_membership_name"){ click_link_or_button("#{saved_member.terms_of_membership.name}") }
    end
    within("#div_description_feature")do
      assert page.has_content?(@terms_of_membership_with_gateway.name) if @terms_of_membership_with_gateway.name
      assert page.has_content?(@terms_of_membership_with_gateway.description) if @terms_of_membership_with_gateway.description
      assert page.has_content?(@terms_of_membership_with_gateway.provisional_days.to_s) if @terms_of_membership_with_gateway.provisional_days
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s) if @terms_of_membership_with_gateway.installment_amount
      assert page.has_content?(@terms_of_membership_with_gateway.installment_type) if @terms_of_membership_with_gateway.installment_type
      # assert page.has_content?(@terms_of_membership_with_gateway.grace_period.to_s) if @terms_of_membership_with_gateway.grace_period
    end
    within("#table_email_template")do
      EmailTemplate::TEMPLATE_TYPES.each do |type|
        if saved_member.current_membership.terms_of_membership.needs_enrollment_approval        
          assert page.has_content?("Test #{type}") 
        else
          assert page.has_content?("Test #{type}") if type != :rejection 
        end
      end 
      EmailTemplate.find_all_by_terms_of_membership_id(saved_member.terms_of_membership.id).each do |et|
        assert page.has_content?(et.client)
        assert page.has_content?(et.template_type)
        assert page.has_content?(et.external_attributes.to_s)
      end 
    end
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
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(@saved_member.member_since_date, :format => :only_date)) }
    within("#td_mi_join_date") { assert page.has_content?(I18n.l(@saved_member.join_date, :format => :only_date)) }    
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(@saved_member.next_retry_bill_date, :format => :only_date)) }    
    within("#td_mi_credit_cards_first_created_at") { assert page.has_content?(I18n.l(@saved_member.credit_cards.first.created_at, :format => :only_date)) }    
  end

  def confirm_email_is_sent(amount_of_days, template_name)
    setup_member(false)
    setup_email_templates

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.find_by_email(unsaved_member.email)  

    @saved_member.current_membership.update_attribute(:join_date, Time.zone.now - amount_of_days.day)
    excecute_like_server(@club.time_zone) do
      TasksHelpers.send_pillar_emails
    end
    sleep 5
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('.nav-tabs'){ click_on 'Communications' }
    within("#communication"){ assert page.has_content?(template_name) }
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations"){ select 'communications', :from => "operation[operation_type]" }

    assert page.has_content?(template_name)
    assert page.has_no_content?("Member enrolled successfully $0.0")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
  end

  ###########################################################
  # TESTS
  ###########################################################

  #Create a member selecting only a kit-card
  test "create member" do
  	setup_member(false)

  	unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
	  created_member = create_member(unsaved_member)

    validate_view_member_base(created_member)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.member.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on 'Fulfillments' }
    within("#fulfillments") { assert page.has_content?('KIT-CARD') }
    assert_equal(Fulfillment.count, 1)
    assert_equal created_member.fulfillments.last.product_sku, 'KIT-CARD'
  end

  # Reject new enrollments if billing is disable
  test "create member with billing disabled" do
    setup_member(false)
    @club.update_attribute :billing_enable, false
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    fill_in_member(unsaved_member)

    assert page.has_content? I18n.t('error_messages.club_is_not_enable_for_new_enrollments', :cs_phone_number => @club.cs_phone_number)
  end

  test "Join a member with auth.net PGC" do
    setup_member(false)
    @club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)  
    created_member = create_member(unsaved_member, nil, nil, false)
  end

  test "Create a member with CC blank" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member,nil,@terms_of_membership_with_gateway.name,true)

    validate_view_member_base(created_member)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }
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
      assert page.has_content?("first_name: can't be blank,is invalid"), "Failure on first_name validation message"
      assert page.has_content?("last_name: can't be blank,is invalid"), "Failure on last_name validation message"
      assert page.has_content?("email: email address is invalid"), "Failure on email validation message"
      assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_country_code validation message"
      assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
      assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_local_number validation message"
      assert page.has_content?("address: is invalid"), "Failure on address validation message"
      assert page.has_content?("state: can't be blank,is invalid"), "Failure on state validation message"
      assert page.has_content?("city: can't be blank,is invalid"), "Failure on city validation message"
      assert page.has_content?("zip: can't be blank,The zip code is not valid for the selected country."), "Failure on zip validation message"
    end
  end

  # TODO: FIX THIS TEST!
  # test "create member without information and with MeS internar error" do
  #   setup_member(false)
  #   active_merchant_stubs(code = "999", message = "internal server error", false )
  #   credit_card = FactoryGirl.build(:credit_card_master_card, :number => "370848940762929", :expire_year => 2020)
  #   unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id, :first_name => "x", :last_name => "x")

  #   visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   click_link_or_button 'New Member'

  #   within("#table_demographic_information")do
  #       fill_in 'member[first_name]', :with => 'x'
  #       fill_in 'member[address]', :with => 'x'
  #       select_country_and_state(unsaved_member.country) 
  #       fill_in 'member[city]', :with => 'x'
  #       fill_in 'member[last_name]', :with => 'x'
  #       fill_in 'member[zip]', :with => unsaved_member.zip
  #   end
  #   within("#table_contact_information")do
  #       fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
  #       fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
  #       fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
  #       fill_in 'member[email]', :with => unsaved_member.email 
  #   end

  #   within("#table_credit_card")do
  #       fill_in 'member[credit_card][number]', :with => credit_card.number
  #       select credit_card.expire_month.to_s, :from => 'member[credit_card][expire_month]'
  #       select credit_card.expire_year.to_s, :from => 'member[credit_card][expire_year]'
  #   end

  #   alert_ok_js
  #   click_link_or_button 'Create Member'
    
  #   within("#error_explanation")do
  #       assert page.has_content?(I18n.t('error_messages.get_token_mes_error')
  #   end
  # end

  test "create member with invalid characters" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_demographic_information") do
        fill_in 'member[first_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[address]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[city]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[last_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[zip]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        select('United States', :from => 'member[country]')
        within('#states_td'){ select('Colorado', :from => 'member[state]') }
    end
    within("#table_contact_information") do
        fill_in 'member[phone_country_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[phone_area_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[phone_local_number]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[email]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation") do
        assert page.has_content?("first_name: is invalid"), "Failure on first_name validation message"
        assert page.has_content?("last_name: is invalid"), "Failure on last_name validation message"
        assert page.has_content?("email: email address is invalid"), "Failure on email validation message"
        assert page.has_content?("phone_country_code: is not a number"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("address: is invalid"), "Failure on address validation message"
        assert page.has_content?("city: is invalid"), "Failure on city validation message"
        assert page.has_content?("zip: The zip code is not valid for the selected country."), "Failure on zip validation message"
    end
  end

  test "create member with letter in phone field" do
    setup_member(false)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_contact_information") do
        fill_in 'member[phone_country_code]', :with => 'werqwr'
        fill_in 'member[phone_area_code]', :with => 'werqwr'
        fill_in 'member[phone_local_number]', :with => 'werqwr'
    end
    within("#table_demographic_information") do
      select('United States', :from => 'member[country]')
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation") do
        assert page.has_content?("phone_country_code: is not a number"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
    end
  end

  test "create member with invalid email" do
    setup_member(false)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_contact_information") do
        fill_in 'member[email]', :with => 'asdfhomail.com'
    end
    within("#table_demographic_information") do
      select('United States', :from => 'member[country]')
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation") do
        assert page.has_content?("email: email address is invalid"), "Failure on email validation message"
    end    
  end
  
  # return to member's profile from terms of membership
  test "show terms of membership" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    validate_terms_of_membership_show_page(@saved_member) 
    click_link_or_button('Return')
  end

  test "create member with gender male" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    fill_in_member(unsaved_member)

    assert find_field('input_gender').value == ('Male')
  end

  test "create member with gender female" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id, :gender => 'F')
    
    fill_in_member(unsaved_member)
    assert find_field('input_gender').value == ('Female')
  end

  test "create member without phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id, :phone_country_code => nil, :phone_area_code => nil, :phone_local_number => nil)
    fill_in_member(unsaved_member)
    within("#error_explanation") do
        assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 characters)")
        assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 characters)")
        assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 characters)")
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
    		assert page.has_content?('zip: The zip code is not valid for the selected country.')
  	end
  end

  test "should not let bill date to be edited" do
  	setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button 'Edit'

    assert page.has_no_selector?('member[bill_date]')
    within("#table_demographic_information") do
    		assert page.has_no_selector?('member[bill_date]')
  	end
    within("#table_contact_information") do
    		assert page.has_no_selector?('member[bill_date]')
  	end
  end

  test "display all operations on member profile" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    saved_member = create_member(unsaved_member)
    generate_operations(saved_member)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => saved_member.id)
    assert find_field('input_first_name').value == saved_member.first_name

    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
    		assert page.has_content?('Member was enrolled')
    		assert page.has_content?('Blacklisted member. Reason: Too much spam')
    		assert page.has_content?('Blacklisted member. Reason: dont like it')
    		assert page.has_content?('Blacklisted member. Reason: testing')
    		assert page.has_content?('Communication sent successfully')
    		assert page.has_content?('Member updated successfully')
    		assert page.has_content?('Member was recovered')
   	end
  end

  test "see operation history from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    10.times{ |time|
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'Member', :member_id => @saved_member.id, 
                                :description => 'Member updated succesfully before' )
      operation.update_attribute :operation_date, operation.operation_date + (time+1).minute
    }
    operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'Member', :member_id => @saved_member.id, 
                                :description => 'Member updated succesfully last' )
    operation.update_attribute :operation_date, operation.operation_date + 11.minute

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table"){ assert page.has_content?('Member updated succesfully last') }
  end

  test "see operations grouped by billing from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 100,
                                :description => 'Member enrolled - 100')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 101,
                                :description => 'Member enrolled - 101')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 103,
                                :description => 'Member enrolled - 102')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    4.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 104,
                                :description => 'Member enrolled - 103')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('billing', :from => 'operation[operation_type]') }
    within("#operations_table")do
      assert page.has_content?('Member enrolled - 101')
      assert page.has_content?('Member enrolled - 102')
      assert page.has_content?('Member enrolled - 103')
      assert page.has_no_content?('Member enrolled - 100')
    end
  end

  test "see operations grouped by profile from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 200,
                                :description => 'Blacklisted member. Reason: Too much spam - 200')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 201,
                                :description => 'Blacklisted member. Reason: Too much spam - 201')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 202,
                                :description => 'Blacklisted member. Reason: Too much spam - 202')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    4.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 203,
                                :description => 'Blacklisted member. Reason: Too much spam - 203')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1   
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('profile', :from => 'operation[operation_type]') }
    within("#operations_table")do
      assert page.has_content?('Blacklisted member. Reason: Too much spam - 201')
      assert page.has_content?('Blacklisted member. Reason: Too much spam - 202')
      assert page.has_content?('Blacklisted member. Reason: Too much spam - 203')
      assert page.has_no_content?('Blacklisted member. Reason: Too much spam - 200')
    end
  end

  test "see operations grouped by communication from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 300,
                                :description => 'Communication sent - 300')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1   
    }
    sleep 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 301,
                                :description => 'Communication sent - 301')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    sleep 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 302,
                                :description => 'Communication sent - 302')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    sleep 1
    4.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 303,
                                :description => 'Communication sent - 303')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('communications', :from => 'operation[operation_type]') }
    within("#operations_table") do
      assert page.has_content?("Communication sent - 303")
      assert page.has_content?("Communication sent - 302")
      assert page.has_content?("Communication sent - 301")
      assert page.has_no_content?("Communication sent - 300")
    end
  end

  test "see operations grouped by others from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    10.times{ |time|
      operation = FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 1000,
                                :description => 'Member was updated successfully - 1000')
      operation.update_attribute :operation_date, operation.operation_date + (time+1).minute
      operation.update_attribute :created_at, operation.created_at + (time+1).minute
    }
    operation = FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'Member', :member_id => @saved_member.id,
                                :operation_type => 1000,
                                :description => 'Member was updated successfully last - 1000')
    operation.update_attribute :operation_date, operation.operation_date + 11.minute
    operation.update_attribute :created_at, operation.created_at + 11.minute
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('others', :from => 'operation[operation_type]') }
    within("#operations_table"){ assert page.has_content?('Member was updated successfully last - 1000') }
  end

  test "create a member with an expired credit card (if actual month is not january)" do
    setup_member(false)
    unless(Time.zone.now.month == 1)
      unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
      credit_card = FactoryGirl.build(:credit_card_master_card, :expire_month => 1, :expire_year => Time.zone.now.year)
      
      visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
      click_link_or_button 'New Member'
      fill_in_member(unsaved_member, credit_card)
      assert page.has_content?("expire_year: expired")
    end
  end

  test "create blank member note" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button 'Add a note'
    click_link_or_button 'Save note'
    within("#member_notes_table"){ assert page.has_content?("Can't be blank.") }
  end

  test "display member with blank product_sku." do
    setup_member
    @saved_member.current_membership.enrollment_info = FactoryGirl.create(:enrollment_info, :product_sku => '', :member_id => @saved_member.id)
    @saved_member.set_as_canceled!

    @saved_member.recovered

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    validate_view_member_base(@saved_member)
  end

  #Recovery time on approval members
  test "Approve member" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,@terms_of_membership_with_approval.name,false)
    reactivation_times = @saved_member.reactivation_times
    membership = @saved_member.current_membership

    validate_view_member_base(@saved_member,'applied')

    confirm_ok_js
    click_link_or_button 'Approve'
    page.has_content?("Member approved")
    @saved_member.reload

    assert_equal reactivation_times, @saved_member.reactivation_times #did not changed

    within("#td_mi_status"){ assert page.has_content?('provisional') }
    within("#td_mi_join_date"){ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    within("#td_mi_next_retry_bill_date"){ assert page.has_content?(I18n.l(Time.zone.now+@terms_of_membership_with_approval.provisional_days.days, :format => :only_date) ) }
    within("#td_mi_reactivation_times"){ assert page.has_content?("0")}
    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('provisional')
    end

    @saved_member.set_as_canceled!
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == unsaved_member.first_name

    click_link_or_button "Recover"
    select(@terms_of_membership_with_approval.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on "Recover"

    assert find_field('input_first_name').value == unsaved_member.first_name

    within("#td_mi_reactivation_times")do
      assert page.has_content?("1")
    end
  end

  test "Recover member from sloop with the same credit card" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    active_merchant_stubs_store(credit_card.number)    
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_approval.name,false)
    reactivation_times = @saved_member.reactivation_times
    membership = @saved_member.current_membership

    @saved_member.reload

    @saved_member.set_as_canceled!
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

    assert find_field('input_first_name').value == unsaved_member.first_name

    # reactivate member using sloop form
    assert_difference('Member.count', 0) do
      assert_difference('CreditCard.count', 0) do
        create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      end
    end
    @saved_member.reload

    assert_not_equal @saved_member.status, "lapsed"

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within("#td_mi_reactivation_times") do
      assert page.has_content?("1")
    end
  end

  test "Reject member" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,@terms_of_membership_with_approval.name,false)
    membership = @saved_member.current_membership

    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('applied')
    end

    confirm_ok_js
    click_link_or_button 'Reject'
    page.has_content?("Member was rejected and now its lapsed.")
    @saved_member.reload

    within("#td_mi_status"){ assert page.has_content?('lapsed') }
    within("#td_mi_join_date"){ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) } 
    
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") { assert page.has_content?("Member was rejected and now its lapsed.") }

    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('lapsed')
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
      assert page.has_no_content?('Home')
      assert page.has_no_content?('Mobile')
      assert page.has_no_content?('Other')
    end
  end

  test "Enroll a member with member approval TOM" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member,nil,@terms_of_membership_with_approval.name,false)
    page.has_selector?('#approve')
    page.has_selector?('#reject')
    validate_view_member_base(@saved_member, 'applied')

    within("#td_mi_status") do
      assert page.has_content?('applied')
    end
    within("#td_mi_join_date") do
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
    end
    within("#td_mi_next_retry_bill_date") do
      assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date))
    end
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") { assert page.has_content?("Member enrolled pending approval successfully $0.0 on TOM(#{@terms_of_membership_with_approval.id}) -#{@terms_of_membership_with_approval.name}-") }
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


    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    click_link_or_button 'Edit'
    page.execute_script("window.jQuery('#member_birth_date').next().click()")
    within(".ui-datepicker-header")do
      find(".ui-datepicker-prev").click
    end
    within(".ui-datepicker-calendar") do
      click_on("13")
    end    
    
    alert_ok_js
    click_link_or_button 'Update Member'
    @saved_member.reload
    within("#table_contact_information")do
      assert page.has_content?(@saved_member.birth_date.to_s) 
    end
  end 

  test "Check Birthday email -  It is send it by CS at night" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    
    @saved_member = create_member(unsaved_member)

    assert find_field('input_first_name').value == unsaved_member.first_name
    @saved_member = Member.find_by_email(unsaved_member.email)
    @saved_member.update_attribute(:birth_date, Time.zone.now)
    excecute_like_server(@club.time_zone) do
      TasksHelpers.send_happy_birthday
    end
    sleep(5)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within('.nav-tabs'){ click_on 'Communications' }
    within("#communication") do
      assert page.has_content?("Test birthday")
      assert page.has_content?("birthday")
      assert_equal(Communication.last.template_type, 'birthday')
    end

    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Communication 'Test birthday' sent")
      visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    end
  end

  test "Send Trial email at Day 7" do
    confirm_email_is_sent 7, "Day 7 - Trial"
  end

  test "Send News email at Day 35" do
    confirm_email_is_sent 35, "Day 35 - News"
  end

  test "Send Deals email at Day 40" do
    confirm_email_is_sent 40, "Day 40 - Deals"
  end

  test "Send Local Chapters email at Day 45" do
    confirm_email_is_sent 45, "Day 45 - Local Chapters"
  end

  test "Send VIP email at Day 50" do
    confirm_email_is_sent 50, "Day 50 - VIP"
  end

  test "Filtering by Communication at Operations tab" do
    setup_member(false)
    setup_email_templates

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_member = Member.find_by_email(unsaved_member.email)  

    #billing
    FactoryGirl.create(:operation, :description => 'enrollment_billing', :operation_type => Settings.operation_types.enrollment_billing, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'membership_billing', :operation_type => Settings.operation_types.membership_billing, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'full_save', :operation_type => Settings.operation_types.full_save, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    #profile
    FactoryGirl.create(:operation, :description => 'reset_club_cash', :operation_type => Settings.operation_types.reset_club_cash, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'future_cancel', :operation_type => Settings.operation_types.future_cancel, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'save_the_sale', :operation_type => Settings.operation_types.save_the_sale, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    #communications
    FactoryGirl.create(:operation, :description => 'active_email', :operation_type => Settings.operation_types.active_email, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'soft_decline_email', :operation_type => Settings.operation_types.soft_decline_email, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'pillar_email', :operation_type => Settings.operation_types.pillar_email, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    #fulfillments
    FactoryGirl.create(:operation, :description => 'from_not_processed_to_in_process', :operation_type => Settings.operation_types.from_not_processed_to_in_process, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'from_sent_to_not_processed', :operation_type => Settings.operation_types.from_sent_to_not_processed, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'from_sent_to_bad_address', :operation_type => Settings.operation_types.from_sent_to_bad_address, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    #vip
    FactoryGirl.create(:operation, :description => 'vip_event_registration', :operation_type => Settings.operation_types.vip_event_registration, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'vip_event_cancelation', :operation_type => Settings.operation_types.vip_event_cancelation, :member_id => created_member.id, :created_by_id => @admin_agent.id)
    #others
    FactoryGirl.create(:operation, :description => 'others', :operation_type => Settings.operation_types.others, :member_id => created_member.id, :created_by_id => @admin_agent.id)


    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => created_member.id)
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations"){ select 'communications', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_content?('active_email')
      assert page.has_content?('soft_decline_email')
      assert page.has_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within("#operations"){ select 'billing', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_content?('enrollment_billing')
      assert page.has_content?('membership_billing')
      assert page.has_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within("#operations"){ select 'profile', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_content?('reset_club_cash')
      assert page.has_content?('future_cancel')
      assert page.has_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within("#operations"){ select 'fulfillments', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_content?('from_not_processed_to_in_process')
      assert page.has_content?('from_sent_to_not_processed')
      assert page.has_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
    end
    within("#operations"){ select 'others', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_no_content?('vip_event_registration')
      assert page.has_no_content?('vip_event_cancelation')
      assert page.has_content?('others')
    end
    within("#operations"){ select 'vip', :from => "operation[operation_type]" }
    within("#operations") do
      assert page.has_no_content?('enrollment_billing')
      assert page.has_no_content?('membership_billing')
      assert page.has_no_content?('full_save')
      assert page.has_no_content?('reset_club_cash')
      assert page.has_no_content?('future_cancel')
      assert page.has_no_content?('save_the_sale')
      assert page.has_no_content?('active_email')
      assert page.has_no_content?('soft_decline_email')
      assert page.has_no_content?('pillar_email')
      assert page.has_no_content?('from_not_processed_to_in_process')
      assert page.has_no_content?('from_sent_to_not_processed')
      assert page.has_no_content?('from_sent_to_bad_address')
      assert page.has_content?('vip_event_registration')
      assert page.has_content?('vip_event_cancelation')
    end
  end

  test "Update a profile with CC used by another member and Family Membership = True" do
    setup_member(false)
    @club_with_family = FactoryGirl.create(:simple_club_with_gateway_with_family)
    @partner = @club_with_family.partner
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club_with_family.id)

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club_with_family.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_member = Member.find_by_email(unsaved_member.email)  

    visit edit_club_path(@club_with_family.partner.prefix, @club_with_family.id)
    assert_nil find(:xpath, "//input[@id='club_family_memberships_allowed']").set(true)

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club_with_family.id)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
  end

  test "Create a member and update a member with letters at Credit Card" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    
    visit members_path( :partner_prefix => unsaved_member.club.partner.prefix, :club_prefix => unsaved_member.club.name )
    click_link_or_button 'New Member'

    credit_card = FactoryGirl.build(:credit_card_master_card) if credit_card.nil?

    type_of_phone_number = (unsaved_member[:type_of_phone_number].blank? ? '' : unsaved_member.type_of_phone_number.capitalize)

    within("#table_demographic_information")do
      fill_in 'member[first_name]', :with => unsaved_member.first_name
      if unsaved_member.gender == "Male" or unsaved_member.gender == "M"
        select("Male", :from => 'member[gender]')
      else
        select("Female", :from => 'member[gender]')
      end
      fill_in 'member[address]', :with => unsaved_member.address
      select_country_and_state(unsaved_member.country) 
      fill_in 'member[city]', :with => unsaved_member.city
      fill_in 'member[last_name]', :with => unsaved_member.last_name
      fill_in 'member[zip]', :with => unsaved_member.zip
    end

    within("#table_contact_information")do
      fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
      fill_in 'member[email]', :with => unsaved_member.email 
    end

    within("#table_credit_card")do
      fill_in 'member[credit_card][number]', :with => "creditcardnumber"
      select credit_card.expire_month.to_s, :from => 'member[credit_card][expire_month]'
      select credit_card.expire_year.to_s, :from => 'member[credit_card][expire_year]'
    end

    click_link_or_button 'Create Member'
    assert page.has_content?(I18n.t("error_messages.member_data_invalid"))
    assert page.has_content?("number: is required")

    fill_in_member(unsaved_member, credit_card)
    assert find_field('input_first_name').value == unsaved_member.first_name

    created_member = Member.find_by_email(unsaved_member.email) 

    add_credit_card(created_member, credit_card)

    visit show_member_path(:partner_prefix => created_member.club.partner.prefix, :club_prefix => created_member.club.name, :member_prefix => created_member.id)
    click_on 'Add a credit card'
    active_merchant_stubs_store(credit_card.number)

    fill_in 'credit_card[number]', :with => "credit_card_number"
    select credit_card.expire_month.to_s, :from => 'credit_card[expire_month]'
    select credit_card.expire_year.to_s, :from => 'credit_card[expire_year]'

    click_on 'Save credit card'

    assert page.has_content?('There was an error with your credit card information. Please verify your information and resubmit. {:number=>["is required"]}')
  end

  # # Remove/Add Club Cash on a member with lifetime TOM
  test "Create a new member in the CS using the Lifetime TOM" do
    setup_member(false)
    @lifetime_terms_of_membership = FactoryGirl.create(:life_time_terms_of_membership, :club_id => @club.id)

    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
    @saved_member = create_member(unsaved_member, nil, @lifetime_terms_of_membership.name, true)
    validate_view_member_base(@saved_member)
    add_club_cash(@saved_member, 10, "Generic description",true)
  end

  test "Do not enroll a member with wrong payment gateway" do
    setup_member(false)
    @club.payment_gateway_configurations.first.update_attribute(:gateway,'fail')
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    fill_in_member(unsaved_member, credit_card, @terms_of_membership_with_gateway.name)
    within("#error_explanation") do
      assert page.has_content?("Member information is invalid.")
      assert page.has_content?("number: An error was encountered while processing your request.")
    end
  end

  test "Create a member selecting only a product" do
    setup_member(false)
    product = FactoryGirl.create(:product, :club_id => @club.id,)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member,nil,nil,false,[product.sku])

    validate_view_member_base(created_member)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.member.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on 'Fulfillments' }
    within("#fulfillments") { assert page.has_content?(product.sku) }
    assert_equal(Fulfillment.count, 1)
    assert_equal created_member.fulfillments.last.product_sku, product.sku
  end

  test "Create a member without selecting any " do
    setup_member(false)
    product = FactoryGirl.create(:product, :club_id => @club.id, :name => 'PRODUCT_RANDOM')
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member,nil,nil,false,[''])

    validate_view_member_base(created_member)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.member.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    assert_equal(Fulfillment.count, 0)
  end

  test "Create a member selecting kit-card and product" do
    setup_member(false)
    product = FactoryGirl.create(:product, :club_id => @club.id)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    created_member = create_member(unsaved_member,nil,nil,false,[product.sku,'KIT-CARD'])

    validate_view_member_base(created_member)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.member.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on 'Fulfillments' }
    within("#fulfillments") { assert page.has_content?(product.sku) }
    within("#fulfillments") { assert page.has_content?('KIT-CARD') }
    assert_equal(Fulfillment.count, 2)
  end
end