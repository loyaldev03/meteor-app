require 'test_helper' 
class UsersEnrollmentTest < ActionDispatch::IntegrationTest

	transactions_table_empty_text = "No data available in table"
	operations_table_empty_text = "No data available in table"
	fulfillments_table_empty_text = "No fulfillments were found"
	communication_table_empty_text = "No communications were found"

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_user(create_new_user = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner

    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    # @communication_type = FactoryGirl.create(:communication_type)
    # @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
  end

  def setup_email_templates
    et = EmailTemplate.new :name => "Day 7 - Trial", :client => :action_mailer, :template_type => 'pillar'
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27648, :mlid => 226095, :site_id => 123 }
    et.days = 7
    et.save!

    et = EmailTemplate.new :name => "Day 35 - News", :client => :action_mailer, :template_type => 'pillar'
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27647, :mlid => 226095, :site_id => 123 }
    et.days = 35
    et.save!

    et = EmailTemplate.new :name => "Day 40 - Deals", :client => :action_mailer, :template_type => 'pillar'
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27651, :mlid => 226095, :site_id => 123 }
    et.days = 40
    et.save!
    
    et = EmailTemplate.new :name => "Day 45 - Local Chapters", :client => :action_mailer, :template_type => 'pillar'
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27650, :mlid => 226095, :site_id => 123 }
    et.days = 45
    et.save!
    
    et = EmailTemplate.new :name => "Day 50 - VIP", :client => :action_mailer, :template_type => 'pillar'
    et.terms_of_membership_id = @terms_of_membership_with_gateway.id
    et.external_attributes = { :trigger_id => 27649, :mlid => 226095, :site_id => 123 }
    et.days = 50
    et.save!
  end

 #  ############################################################
 #  # UTILS
 #  ############################################################

  def validate_terms_of_membership_show_page(saved_user)
    within("#table_membership_information")do
      within("#td_mi_terms_of_membership_name"){ click_link_or_button("#{saved_user.terms_of_membership.name}") }
    end
    within("#div_description_feature")do
      assert page.has_content?(@terms_of_membership_with_gateway.name) if @terms_of_membership_with_gateway.name
      assert page.has_content?(@terms_of_membership_with_gateway.description) if @terms_of_membership_with_gateway.description
      assert page.has_content?(@terms_of_membership_with_gateway.provisional_days.to_s) if @terms_of_membership_with_gateway.provisional_days
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s) if @terms_of_membership_with_gateway.installment_amount
      # assert page.has_content?(@terms_of_membership_with_gateway.grace_period.to_s) if @terms_of_membership_with_gateway.grace_period
    end
    within("#table_email_template")do
      EmailTemplate::TEMPLATE_TYPES.each do |type|
        if type != :pillar
          if saved_user.current_membership.terms_of_membership.needs_enrollment_approval        
            assert page.has_content?("Test #{type}") 
          else
            assert page.has_content?("Test #{type}") if type != :rejection 
          end
        end
      end 
      EmailTemplate.where(terms_of_membership_id: saved_user.terms_of_membership.id).each do |et|
        assert page.has_content?(et.client)
        assert page.has_content?(et.template_type)
        assert page.has_content?(et.external_attributes.to_s)
      end 
    end
  end


  def generate_operations(user)
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.enrollment_billing, :description => 'user was enrolled' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.cancel, :description => 'Blacklisted user. Reason: Too much spam' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.save_the_sale, :description => 'Blacklisted user. Reason: dont like it' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.recovery, :description => 'Blacklisted user. Reason: testing' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.active_email, :description => 'Communication sent successfully' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'user',
                       :user_id => user.id, :operation_type => Settings.operation_types.prebill_email, :description => 'Communication was not sent' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.others, :description => 'user updated successfully' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'user',
  										 :user_id => user.id, :operation_type => Settings.operation_types.others, :description => 'user was recovered' )
  end

  # When creating user from web, should add KIT and CARD fulfillments 

  def validate_timezone_dates(timezone)
    @club.time_zone = timezone
    @club.save
    Time.zone = timezone
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(@saved_user.member_since_date, :format => :only_date)) }
    within("#td_mi_join_date") { assert page.has_content?(I18n.l(@saved_user.join_date, :format => :only_date)) }    
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(@saved_user.next_retry_bill_date, :format => :only_date)) }    
    within("#td_mi_credit_cards_first_created_at") { assert page.has_content?(I18n.l(@saved_user.credit_cards.first.created_at, :format => :only_date)) }    
  end

  def confirm_email_is_sent(amount_of_days, template_name)
    setup_user(false)
    setup_email_templates

    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by_email(unsaved_user.email)  

    @saved_user.current_membership.update_attribute(:join_date, Time.zone.now - amount_of_days.day)
    excecute_like_server(@club.time_zone) do
      TasksHelpers.send_pillar_emails
    end
    sleep 5
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('.nav-tabs'){ click_on 'Communications' }
    within("#communications"){ assert page.has_content?(template_name) }
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations"){ select 'communications', :from => "operation[operation_type]" }

    assert page.has_content?(template_name)
    assert page.has_no_content?("Member enrolled successfully $0.0")
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
  end

  # ##########################################################
  # TESTS
  # ##########################################################

  test "create user" do
  	setup_user(false)

  	unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
	  created_user = create_user(unsaved_user)

    validate_view_user_base(created_user)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.user.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on 'Fulfillments' }
    within("#fulfillments") { assert page.has_content?(created_user.fulfillments.first.product_sku) }
    assert_equal(Fulfillment.count, 1)
    assert_equal created_user.fulfillments.last.product_sku, created_user.product_to_send.sku
  end

  # Reject new enrollments if billing is disable
  test "create user with billing disabled" do
    setup_user(false)
    @club.update_attribute :billing_enable, false
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    fill_in_user(unsaved_user)

    assert page.has_content? I18n.t('error_messages.club_is_not_enable_for_new_enrollments', :cs_phone_number => @club.cs_phone_number)
  end

  test "Join an user with auth.net PGC" do
    setup_user(false)
    @club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)  
    created_user = create_user(unsaved_user, nil, nil, false)
  end

  test "Create an user with CC blank" do
    setup_user(false)

    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    created_user = create_user(unsaved_user,nil,@terms_of_membership_with_gateway.name,true)

    validate_view_user_base(created_user)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }
  end

	test "new user for with external_id not requiered" do
  	setup_user(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    created_user = create_user(unsaved_user)
  end

  test "show dates according to club timezones" do
    setup_user
    validate_timezone_dates("Eastern Time (US & Canada)")
    validate_timezone_dates("Ekaterinburg")
  end

  test "create user without information" do
    setup_user
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New User'
    within("#table_demographic_information") {
      select('United States', :from => 'user[country]')
    }
    alert_ok_js
    click_link_or_button 'Create User'
    within("#error_explanation")do
      assert page.has_content?("first_name: can't be blank,is invalid"), "Failure on first_name validation message"
      assert page.has_content?("last_name: can't be blank,is invalid"), "Failure on last_name validation message"
      assert page.has_content?("email: email address is invalid"), "Failure on email validation message"
      assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 character)"), "Failure on phone_country_code validation message"
      assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 character)"), "Failure on phone_area_code validation message"
      assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 character)"), "Failure on phone_local_number validation message"
      assert page.has_content?("address: is invalid"), "Failure on address validation message"
      assert page.has_content?("state: can't be blank,is invalid"), "Failure on state validation message"
      assert page.has_content?("city: can't be blank,is invalid"), "Failure on city validation message"
      assert page.has_content?("zip: can't be blank,The zip code is not valid for the selected country."), "Failure on zip validation message"
    end
  end

  # TODO: FIX THIS TEST!
  # test "create user without information and with MeS internar error" do
  #   setup_user(false)
  #   active_merchant_stubs(code = "999", message = "internal server error", false )
  #   credit_card = FactoryGirl.build(:credit_card_master_card, :number => "370848940762929", :expire_year => 2020)
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id, :first_name => "x", :last_name => "x")

  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   click_link_or_button 'New User'

  #   within("#table_demographic_information")do
  #       fill_in 'user[first_name]', :with => 'x'
  #       fill_in 'user[address]', :with => 'x'
  #       select_country_and_state(unsaved_user.country) 
  #       fill_in 'user[city]', :with => 'x'
  #       fill_in 'user[last_name]', :with => 'x'
  #       fill_in 'user[zip]', :with => unsaved_user.zip
  #   end
  #   within("#table_contact_information")do
  #       fill_in 'user[phone_country_code]', :with => unsaved_user.phone_country_code
  #       fill_in 'user[phone_area_code]', :with => unsaved_user.phone_area_code
  #       fill_in 'user[phone_local_number]', :with => unsaved_user.phone_local_number
  #       fill_in 'user[email]', :with => unsaved_user.email 
  #   end

  #   within("#table_credit_card")do
  #       fill_in 'user[credit_card][number]', :with => credit_card.number
  #       select credit_card.expire_month.to_s, :from => 'user[credit_card][expire_month]'
  #       select credit_card.expire_year.to_s, :from => 'user[credit_card][expire_year]'
  #   end

  #   alert_ok_js
  #   click_link_or_button 'Create User'
    
  #   within("#error_explanation")do
  #       assert page.has_content?(I18n.t('error_messages.get_token_mes_error')
  #   end
  # end

  test "create user with invalid characters" do
    setup_user
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New User'
    within("#table_demographic_information") do
        fill_in 'user[first_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[address]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[city]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[last_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[zip]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        select('United States', :from => 'user[country]')
        within('#states_td'){ select('Colorado', :from => 'user[state]') }
    end
    within("#table_contact_information") do
        fill_in 'user[phone_country_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[phone_area_code]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[phone_local_number]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'user[email]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
    end
    alert_ok_js
    click_link_or_button 'Create User'
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

  test "create user with letter in phone field" do
    setup_user(false)
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New User'
    within("#table_contact_information") do
        fill_in 'user[phone_country_code]', :with => 'werqwr'
        fill_in 'user[phone_area_code]', :with => 'werqwr'
        fill_in 'user[phone_local_number]', :with => 'werqwr'
    end
    within("#table_demographic_information") do
      select('United States', :from => 'user[country]')
    end
    alert_ok_js
    click_link_or_button 'Create User'
    within("#error_explanation") do
        assert page.has_content?("phone_country_code: is not a number"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_area_code: is not a number"), "Failure on phone_area_code validation message"
    end
  end

  test "create user with invalid email" do
    setup_user(false)
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New User'
    within("#table_contact_information") do
        fill_in 'user[email]', :with => 'asdfhomail.com'
    end
    within("#table_demographic_information") do
      select('United States', :from => 'user[country]')
    end
    alert_ok_js
    click_link_or_button 'Create User'
    within("#error_explanation") do
        assert page.has_content?("email: email address is invalid"), "Failure on email validation message"
    end    
  end
  
  # return to user's profile from terms of membership
  test "show terms of membership" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    validate_terms_of_membership_show_page(@saved_user) 
    click_link_or_button('Return')
  end

  test "create user with gender male" do
    setup_user
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id, :gender => 'M')
    create_user(unsaved_user)
    assert find_field('input_gender').value == ('Male')
  end

  test "create user with gender female" do
    setup_user
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id, :gender => 'F')
    create_user(unsaved_user)
    assert find_field('input_gender').value == ('Female')  
  end

  test "create user without phone number" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id, :phone_country_code => nil, :phone_area_code => nil, :phone_local_number => nil)
    fill_in_user(unsaved_user)
    within("#error_explanation") do
        assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 character)")
        assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 character)")
        assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 character)")
    end
  end

  # create user with phone number
  # create user with 'home' telephone type
  test "should create user and display type of phone number" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id, :type_of_phone_number => 'home')
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    saved_user = create_user(unsaved_user, credit_card)
    validate_view_user_base(saved_user)
  end

  test "create user with canadian zip" do
  	setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, 
                                         :club_id => @club.id, 
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'QC',
                                         :zip => 'H3G 1M8',
                                         :country => 'Canada')
    
    saved_user = create_user(unsaved_user)
    validate_view_user_base(saved_user)
  end

  test "create user with invalid canadian zip" do
  	setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, 
                                         :club_id => @club.id, 
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'QC',
                                         :zip => '%^tYU2123',
                                         :country => 'CA')

    fill_in_user(unsaved_user)
    within('#error_explanation')do
    		assert page.has_content?('zip: The zip code is not valid for the selected country.')
  	end
  end

  test "should not let bill date to be edited" do
  	setup_user
    sleep 1
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_link_or_button 'Edit'

    assert page.has_no_selector?('user[bill_date]')
    within("#table_demographic_information") do
    		assert page.has_no_selector?('user[bill_date]')
  	end
    within("#table_contact_information") do
    		assert page.has_no_selector?('user[bill_date]')
  	end
  end

  test "display all operations on user profile" do
  	setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    saved_user = create_user(unsaved_user)
    generate_operations(saved_user)

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => saved_user.id)
    assert find_field('input_first_name').value == saved_user.first_name

    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
    		assert page.has_content?('user was enrolled')
    		assert page.has_content?('Blacklisted user. Reason: Too much spam')
    		assert page.has_content?('Blacklisted user. Reason: dont like it')
    		assert page.has_content?('Blacklisted user. Reason: testing')
    		assert page.has_content?('Communication sent successfully')
    		assert page.has_content?('user updated successfully')
    		assert page.has_content?('user was recovered')
   	end
  end

  test "see operation history from lastest to newest" do
    setup_user
    generate_operations(@saved_user)
    10.times{ |time|
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'user', :user_id => @saved_user.id, 
                                :description => 'user updated succesfully before' )
      operation.update_attribute :operation_date, operation.operation_date + (time+1).minute
    }
    operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id, 
                                :resource_type => 'user', :user_id => @saved_user.id, 
                                :description => 'user updated succesfully last' )
    operation.update_attribute :operation_date, operation.operation_date + 11.minute

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations_table"){ assert page.has_content?('user updated succesfully last') }
  end

  test "see operations grouped by billing from lastest to newest" do
    setup_user
    generate_operations(@saved_user)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 100,
                                :description => 'member enrolled - 100')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 101,
                                :description => 'member enrolled - 101')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 103,
                                :description => 'member enrolled - 102')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    4.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 104,
                                :description => 'member enrolled - 103')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('billing', :from => 'operation[operation_type]') }
    within("#operations_table")do
      assert page.has_content?('member enrolled - 101')
      assert page.has_content?('member enrolled - 102')
      assert page.has_content?('member enrolled - 103')
      assert page.has_no_content?('member enrolled - 100')
    end
  end

  test "see operations grouped by profile from lastest to newest" do
    setup_user
    generate_operations(@saved_user)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 200,
                                :description => 'Blacklisted user. Reason: Too much spam - 200')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 201,
                                :description => 'Blacklisted user. Reason: Too much spam - 201')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    3.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 202,
                                :description => 'Blacklisted user. Reason: Too much spam - 202')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    4.times{
      operation = FactoryGirl.create(:operation_billing, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 203,
                                :description => 'Blacklisted user. Reason: Too much spam - 203')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1   
    }
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('profile', :from => 'operation[operation_type]') }
    within("#operations_table")do
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 201')
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 202')
      assert page.has_content?('Blacklisted user. Reason: Too much spam - 203')
      assert page.has_no_content?('Blacklisted user. Reason: Too much spam - 200')
    end
  end

  test "see operations grouped by communication from lastest to newest" do
    setup_user
    generate_operations(@saved_user)
    time = 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 300,
                                :description => 'Communication sent - 300')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1   
    }
    sleep 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 301,
                                :description => 'Communication sent - 301')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    sleep 1
    3.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 302,
                                :description => 'Communication sent - 302')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    sleep 1
    4.times{
      operation = FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 303,
                                :description => 'Communication sent - 303')
      operation.update_attribute :operation_date, operation.operation_date + time.minute
      time=time+1
    }
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
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
    setup_user
    generate_operations(@saved_user)
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    10.times{ |time|
      operation = FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 1000,
                                :description => 'user was updated successfully - 1000')
      operation.update_attribute :operation_date, operation.operation_date + (time+1).minute
      operation.update_attribute :created_at, operation.created_at + (time+1).minute
    }
    operation = FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id,
                                :resource_type => 'user', :user_id => @saved_user.id,
                                :operation_type => 1000,
                                :description => 'user was updated successfully last - 1000')
    operation.update_attribute :operation_date, operation.operation_date + 11.minute
    operation.update_attribute :created_at, operation.created_at + 11.minute
    within('.nav-tabs'){ click_on 'Operations'}
    within("#dataTableSelect"){ select('others', :from => 'operation[operation_type]') }
    within("#operations_table"){ assert page.has_content?('user was updated successfully last - 1000') }
  end

  test "create an user with an expired credit card (if actual month is not january)" do
    setup_user(false)
    unless(Time.zone.now.month == 1)
      unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
      credit_card = FactoryGirl.build(:credit_card_master_card, :expire_month => 1, :expire_year => Time.zone.now.year)
      
      visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
      click_link_or_button 'New User'
      fill_in_user(unsaved_user, credit_card)
      assert page.has_content?("expire_year: expired")
    end
  end

  test "create blank user note" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_link_or_button 'Add a note'
    click_link_or_button 'Save note'
    within("#user_notes_table"){ assert page.has_content?("Can't be blank.") }
  end

  test "display user with blank product_sku." do
    setup_user
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent, product_sku: '' })
    @saved_user.set_as_canceled!
    @saved_user.recovered
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    validate_view_user_base(@saved_user)
  end

  #Recovery time on approval users
  test "Approve user" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    @saved_user = create_user(unsaved_user,nil,@terms_of_membership_with_approval.name,false)
    membership = @saved_user.current_membership

    validate_view_user_base(@saved_user,'applied')

    confirm_ok_js
    click_link_or_button 'Approve'
    page.has_content?("user approved")
    @saved_user.reload

    within("#td_mi_status"){ assert page.has_content?('provisional') }
    within("#td_mi_join_date"){ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    within("#td_mi_next_retry_bill_date"){ assert page.has_content?(I18n.l(Time.zone.now+@terms_of_membership_with_approval.provisional_days.days, :format => :only_date) ) }
    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('provisional')
    end

    @saved_user.set_as_canceled!
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == unsaved_user.first_name

    click_link_or_button "Recover"
    select(@terms_of_membership_with_approval.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on "Recover"

    assert find_field('input_first_name').value == unsaved_user.first_name
  end

  test "Recover user from sloop with the same credit card" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    active_merchant_stubs_store(credit_card.number)    
    @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_approval.name,false)
    membership = @saved_user.current_membership

    @saved_user.reload

    @saved_user.set_as_canceled!
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)

    assert find_field('input_first_name').value == unsaved_user.first_name

    # reactivate user using sloop form
    assert_difference('User.count', 0) do
      assert_difference('CreditCard.count', 0) do
        create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      end
    end
    @saved_user.reload

    assert_not_equal @saved_user.status, "lapsed"

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
  end

  test "Reject user" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    @saved_user = create_user(unsaved_user,nil,@terms_of_membership_with_approval.name,false)
    membership = @saved_user.current_membership

    within(".nav-tabs"){ click_on("Memberships") }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('applied')
    end

    confirm_ok_js
    click_link_or_button 'Reject'
    page.has_content?("user was rejected and now its lapsed.")
    @saved_user.reload

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

  test "create user without gender" do
    setup_user(false)

    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id, :gender => '')
    @saved_user = create_user(unsaved_user)

    validate_view_user_base(@saved_user)
  end

  test "Create an user without Telephone Type" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :type_of_phone_number => '', :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)

    saved_user = create_user(unsaved_user)

    within("#table_contact_information")do
      assert page.has_no_content?('Home')
      assert page.has_no_content?('Mobile')
      assert page.has_no_content?('Other')
    end
  end

  test "Enroll an user with user approval TOM" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    @saved_user = create_user(unsaved_user,nil,@terms_of_membership_with_approval.name,false)
    page.has_selector?('#approve')
    page.has_selector?('#reject')
    validate_view_user_base(@saved_user, 'applied')

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

  test "Enroll an user should create membership" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    @saved_user = create_user(unsaved_user)
    validate_view_user_base(@saved_user)
    
    membership = @saved_user.current_membership
    
  end 

  test "Update Birthday after 12 like a day" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by_email(unsaved_user.email)  


    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_link_or_button 'Edit'
    page.execute_script("window.jQuery('#user_birth_date').next().click()")
    within(".ui-datepicker-header")do
      find(".ui-datepicker-prev").click
    end
    within(".ui-datepicker-calendar") do
      click_on("13")
    end
    
    alert_ok_js
    click_link_or_button 'Update User'
    within("#table_contact_information")do
      @saved_user.reload
      assert page.has_content?(@saved_user.birth_date.to_s) 
    end
  end 

  test "Check Birthday email -  It is send it by CS at night" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    
    @saved_user = create_user(unsaved_user)

    assert find_field('input_first_name').value == unsaved_user.first_name
    @saved_user = User.find_by_email(unsaved_user.email)
    @saved_user.update_attribute(:birth_date, Time.zone.now)
    excecute_like_server(@club.time_zone) do
      TasksHelpers.send_happy_birthday
    end
    sleep(5)
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs'){ click_on 'Communications' }
    within("#communications") do
      find("tr", text: "Test birthday")
      assert_equal(Communication.last.template_type, 'birthday')
    end

    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Communication 'Test birthday' sent")
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
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
    setup_user(false)
    setup_email_templates

    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_user = User.find_by_email(unsaved_user.email)  

    #billing
    FactoryGirl.create(:operation, :description => 'enrollment_billing', :operation_type => Settings.operation_types.enrollment_billing, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'membership_billing', :operation_type => Settings.operation_types.membership_billing, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'full_save', :operation_type => Settings.operation_types.full_save, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    #profile
    FactoryGirl.create(:operation, :description => 'reset_club_cash', :operation_type => Settings.operation_types.reset_club_cash, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'future_cancel', :operation_type => Settings.operation_types.future_cancel, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'save_the_sale', :operation_type => Settings.operation_types.save_the_sale, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    #communications
    FactoryGirl.create(:operation, :description => 'active_email', :operation_type => Settings.operation_types.active_email, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'soft_decline_email', :operation_type => Settings.operation_types.soft_decline_email, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'pillar_email', :operation_type => Settings.operation_types.pillar_email, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    #fulfillments
    FactoryGirl.create(:operation, :description => 'from_not_processed_to_in_process', :operation_type => Settings.operation_types.from_not_processed_to_in_process, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'from_sent_to_not_processed', :operation_type => Settings.operation_types.from_sent_to_not_processed, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'from_sent_to_bad_address', :operation_type => Settings.operation_types.from_sent_to_bad_address, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    #vip
    FactoryGirl.create(:operation, :description => 'vip_event_registration', :operation_type => Settings.operation_types.vip_event_registration, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    FactoryGirl.create(:operation, :description => 'vip_event_cancelation', :operation_type => Settings.operation_types.vip_event_cancelation, :user_id => created_user.id, :created_by_id => @admin_agent.id)
    #others
    FactoryGirl.create(:operation, :description => 'others', :operation_type => Settings.operation_types.others, :user_id => created_user.id, :created_by_id => @admin_agent.id)


    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => created_user.id)
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

  test "Update a profile with CC used by another user and Family membership = True" do
    setup_user(false)
    @club_with_family = FactoryGirl.create(:simple_club_with_gateway_with_family)
    @partner = @club_with_family.partner
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club_with_family.id)

    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club_with_family.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    created_user = User.find_by_email(unsaved_user.email)  

    visit edit_club_path(@club_with_family.partner.prefix, @club_with_family.id)
    assert_nil find(:xpath, "//input[@id='club_family_memberships_allowed']").set(true)

    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club_with_family.id)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
  end

  test "Create an user and update an user with letters at Credit Card" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:membership_with_enrollment_info)
    
    visit users_path( :partner_prefix => unsaved_user.club.partner.prefix, :club_prefix => unsaved_user.club.name )
    click_link_or_button 'New User'

    credit_card = FactoryGirl.build(:credit_card_master_card) if credit_card.nil?

    type_of_phone_number = (unsaved_user[:type_of_phone_number].blank? ? '' : unsaved_user.type_of_phone_number.capitalize)

    within("#table_demographic_information")do
      fill_in 'user[first_name]', :with => unsaved_user.first_name
      if unsaved_user.gender == "Male" or unsaved_user.gender == "M"
        select("Male", :from => 'user[gender]')
      else
        select("Female", :from => 'user[gender]')
      end
      fill_in 'user[address]', :with => unsaved_user.address
      select_country_and_state(unsaved_user.country) 
      fill_in 'user[city]', :with => unsaved_user.city
      fill_in 'user[last_name]', :with => unsaved_user.last_name
      fill_in 'user[zip]', :with => unsaved_user.zip
    end

    within("#table_contact_information")do
      fill_in 'user[phone_country_code]', :with => unsaved_user.phone_country_code
      fill_in 'user[phone_area_code]', :with => unsaved_user.phone_area_code
      fill_in 'user[phone_local_number]', :with => unsaved_user.phone_local_number
      fill_in 'user[email]', :with => unsaved_user.email 
    end

    within("#table_credit_card")do
      fill_in 'user[credit_card][number]', :with => "creditcardnumber"
      select credit_card.expire_month.to_s, :from => 'user[credit_card][expire_month]'
      select credit_card.expire_year.to_s, :from => 'user[credit_card][expire_year]'
    end

    click_link_or_button 'Create User'
    assert page.has_content?(I18n.t("error_messages.user_data_invalid"))
    assert page.has_content?("number: is required")

    fill_in_user(unsaved_user, credit_card)
    sleep 3
    assert find_field('input_first_name').value == unsaved_user.first_name

    created_user = User.find_by_email(unsaved_user.email) 

    add_credit_card(created_user, credit_card)

    visit show_user_path(:partner_prefix => created_user.club.partner.prefix, :club_prefix => created_user.club.name, :user_prefix => created_user.id)
    click_on 'Add a credit card'
    active_merchant_stubs_store(credit_card.number)

    fill_in 'credit_card[number]', :with => "credit_card_number"
    select credit_card.expire_month.to_s, :from => 'credit_card[expire_month]'
    select credit_card.expire_year.to_s, :from => 'credit_card[expire_year]'

    click_on 'Save credit card'

    assert page.has_content?('There was an error with your credit card information. Please verify your information and resubmit. {:number=>["is required"]}')
  end

  # # Remove/Add Club Cash on an user with lifetime TOM
  test "Create a new user in the CS using the Lifetime TOM" do
    setup_user(false)
    @lifetime_terms_of_membership = FactoryGirl.create(:life_time_terms_of_membership, :club_id => @club.id)

    unsaved_user = FactoryGirl.build(:user_with_cc, :club_id => @club.id)
    @saved_user = create_user(unsaved_user, nil, @lifetime_terms_of_membership.name, true)
    validate_view_user_base(@saved_user)
    add_club_cash(@saved_user, 10, "Generic description",true)
  end

  test "Do not enroll an user with wrong payment gateway" do
    setup_user(false)
    @club.payment_gateway_configurations.first.update_attribute(:gateway,'fail')
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    fill_in_user(unsaved_user, credit_card, @terms_of_membership_with_gateway.name)
    within("#error_explanation") do
      assert page.has_content?("Member information is invalid.")
      assert page.has_content?("number: An error was encountered while processing your request.")
    end
  end

  test "Create an user without selecting any " do
    setup_user(false)
    product = FactoryGirl.create(:product, :club_id => @club.id, sku: 'PRODUCT_RANDOM')
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    created_user = create_user(unsaved_user,nil,nil,false,'')
    
    validate_view_user_base(created_user)
    within(".nav-tabs"){ click_on 'Operations' }
    within("#operations") { assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-") }
    within("#table_enrollment_info") { assert page.has_content?( I18n.t('activerecord.attributes.user.has_no_preferences_saved')) }
    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    assert_equal(Fulfillment.count, 0)
  end
end