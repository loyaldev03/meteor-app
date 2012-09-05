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
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    if create_new_member
	    @saved_member = FactoryGirl.create(:active_member, 
	      :club_id => @club.id, 
	      :terms_of_membership => @terms_of_membership_with_gateway,
	      :created_by => @admin_agent)

			@saved_member.reload
		end

    sign_in_as(@admin_agent)
   end

	#Only for search test
  def setup_search
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    20.times{ FactoryGirl.create(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent) }
    10.times{ FactoryGirl.create(:lapsed_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent) }
    10.times{ FactoryGirl.create(:provisional_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent) }
    @search_member = Member.first
    sign_in_as(@admin_agent)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

 #  ############################################################
 #  # UTILS
 #  ############################################################

  def search_member(field_selector, value, validate_obj)
    fill_in field_selector, :with => value unless value.nil?
    click_on 'Search'

    within("#members") do
      wait_until {
        assert page.has_content?(validate_obj.status)
        assert page.has_content?("#{validate_obj.visible_id}")
        assert page.has_content?(validate_obj.full_name)
        assert page.has_content?(validate_obj.full_address)
      }

      if !validate_obj.external_id.nil?
      	assert page.has_content?(validate_obj.external_id)
      end
    end
  end

  def validate_view_member_base(member)

    assert find_field('input_visible_id').value == "#{member.visible_id}"
    assert find_field('input_first_name').value == member.first_name
    assert find_field('input_last_name').value == member.last_name
    assert find_field('input_gender').value == (member.gender == 'F' ? 'Female' : 'Male')
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
      assert page.has_content?(member.type_of_phone_number)
      assert page.has_content?("#{member.birth_date}")
      assert page.has_selector?('#link_member_set_unreachable')     
    end

    active_credit_card = member.active_credit_card
    within("#table_active_credit_card") do
      assert page.has_content?("#{active_credit_card.number}")
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    end

    within("#table_membership_information") do
      assert page.has_content?(member.status)
      within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(member.member_since_date, :format => :only_date)) }
      
      assert page.has_content?(member.terms_of_membership.name)
      
      within("#td_mi_reactivation_times") { assert page.has_content?("#{member.reactivation_times}") }
      
      assert page.has_content?(member.created_by.username)

      within("#td_mi_reactivation_times") { assert page.has_content?("#{member.reactivation_times}") }
      
      within("#td_mi_recycled_times") { assert page.has_content?("#{member.recycled_times}") }
      
      assert page.has_no_selector?("#td_mi_external_id")
      
      within("#td_mi_join_date") { assert page.has_content?(I18n.l(member.join_date, :format => :only_date)) }

      within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(member.next_retry_bill_date, :format => :only_date)) }

      assert page.has_selector?("#link_member_change_next_bill_date")

      within("#td_mi_club_cash_amount") { assert page.has_content?("#{member.club_cash_amount.to_f}") }

			assert page.has_selector?("#link_member_add_club_cash")

      within("#td_mi_credit_cards_first_created_at") { assert page.has_content?(I18n.l(member.credit_cards.first.created_at, :format => :only_date)) }

      within("#td_mi_quota") { assert page.has_content?("#{member.quota}") }
      
    end    
    
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
    search_member("member[member_id]", "#{@search_member.visible_id}", @search_member)
  end

	test "search member by first name" do
		setup_search
	 	search_member("member[first_name]", "#{@search_member.first_name}", @search_member)
	end


  test "search member with empty form" do
    setup_search
    click_on 'Search'
    
    within("#members") {
    	wait_until {
    		assert page.has_content?("Search Result")
				assert page.has_selector?(".pagination")
				assert page.has_content?(Member.first.full_name)
    	}
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
    	assert page.has_content?("Next")
      click_on("2")
    end

    wait_until {
			assert page.has_content?(Member.last.full_name)
    }
    
  end

  test "search a member with next bill date in past" do
    setup_search
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    assert page.evaluate_script("window.jQuery('.ui-datepicker-prev').is('.ui-state-disabled')")
  end

  
  test "display member" do
    setup_search
    search_member("member[member_id]", "#{@search_member.visible_id}", @search_member)
    within("#members") do
      wait_until {
        assert page.has_content?("#{@search_member.visible_id}")
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

	def create_new_member(unsaved_member, cc_blank = false)
		visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

		click_on 'New Member'

  	within("#table_demographic_information") {
		  fill_in 'member[first_name]', :with => unsaved_member.first_name
	 	  fill_in 'member[last_name]', :with => unsaved_member.last_name
	  	fill_in 'member[city]', :with => unsaved_member.city
	  	fill_in 'member[address]', :with => unsaved_member.address
	  	fill_in 'member[zip]', :with => unsaved_member.zip
	  	fill_in 'member[state]', :with => unsaved_member.state
	  	select('M', :from => 'member[gender]')
	  	select('US', :from => 'member[country]')
		}

		page.execute_script("window.jQuery('#member_birth_date').next().click()")
	  within(".ui-datepicker-calendar") do
	  	click_on("1")
	  end

		within("#table_contact_information") {
			fill_in 'member[email]', :with => unsaved_member.email
			fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
			fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
			fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
			select('Home', :from => 'member[type_of_phone_number]')
			select(@terms_of_membership_with_gateway.name, :from => 'member[terms_of_membership_id]')
		}

    if cc_blank
      check('setter[cc_blank]')
    else
      within("#table_credit_card") {	
  			fill_in 'member[credit_card][number]', :with => "#{unsaved_member.active_credit_card.number}"
  			fill_in 'member[credit_card][expire_month]', :with => "#{unsaved_member.active_credit_card.expire_month}"
  			fill_in 'member[credit_card][expire_year]', :with => "#{unsaved_member.active_credit_card.expire_year}"
  		}
    end
    
      
    unless unsaved_member.external_id.nil?
    	fill_in 'member[external_id]', :with => unsaved_member.external_id
    end 

    alert_ok_js

    assert_difference ['Member.count', 'CreditCard.count'] do 
    	click_link_or_button 'Create Member'
    	sleep(5) #Wait for API response
    end
    assert page.has_content?("#{unsaved_member.first_name} #{unsaved_member.last_name}")

	end

  test "create member" do
  	setup_member(false)

  	unsaved_member = FactoryGirl.build(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)

 		create_new_member(unsaved_member)
    created_member = Member.where(:first_name => unsaved_member.first_name, :last_name => unsaved_member.last_name).first
    
    validate_view_member_base(created_member)

    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }

    active_credit_card = created_member.active_credit_card
    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }

    within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }

    within("#communication") { assert page.has_content?(communication_table_empty_text) }


  end

  test "Create a member with CC blank" do
    setup_member(false)

    unsaved_member = FactoryGirl.build(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)

    create_new_member(unsaved_member, true)
    
    created_member = Member.where(:first_name => unsaved_member.first_name, :last_name => unsaved_member.last_name).first
    
    validate_view_member_base(created_member)

    within("#operations_table") { assert page.has_content?("Member enrolled successfully $0.0") }

    active_credit_card = created_member.active_credit_card
    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }

    within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }

    within("#communication") { assert page.has_content?(communication_table_empty_text) }


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
    	sleep(5) #Wait for API response
    end

    assert page.has_content?("#{@saved_member.first_name} #{@saved_member.last_name}")

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

    assert page.has_content?("#{@saved_member.first_name} #{@saved_member.last_name}")
		assert find_field('input_member_group_type').value == 'Notable'
    
  end


  test "create a member inside a club with external_id in true" do
  	setup_member(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_member = FactoryGirl.build(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent, :external_id => "9876543210")

  	visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'New Member'
    create_new_member(unsaved_member)

    member = Member.last

    within("#td_mi_external_id") { 
    	assert page.has_content?(member.external_id) 
    }
      
  end

	test "new member for with external_id not requiered" do
  	setup_member(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_member = FactoryGirl.build(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)

  	visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'New Member'
    create_new_member(unsaved_member)

  end

  test "display external_id at member search" do
  	setup_member(false)
  	@club.requires_external_id = true
  	@club.save!

  	unsaved_member = FactoryGirl.build(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent, :external_id => "9876543210")

  	visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'New Member'
    create_new_member(unsaved_member)

    member = Member.last

    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)    
    search_member("member[member_id]", "#{member.visible_id}", member)

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

    assert page.has_content?("The Credit Card #{cc_number[-4,4]} was successfully added and setted as active")
    
    within("#table_active_credit_card") do
      assert page.has_content?(cc_number)
      assert page.has_content?("#{cc_month} / #{cc_year}")
    end

    wait_until {
      within("#operations_table") {
          assert page.has_content?("Credit card #{cc_number[-4,4]} added and set active") 
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

    assert page.has_content?("The Credit Card #{old_active_credit_card.number.to_s[-4,4]} was activated")
    
    within("#credit_cards") { 
      assert page.has_content?("#{old_active_credit_card.number}") 
      assert page.has_content?("#{old_active_credit_card.expire_month} / #{old_active_credit_card.expire_year}")
    }
    
  end


  test "add new note" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add a note'
    
    text_note = "text note 123456789"

    select(@communication_type.name, :from => 'member_note[communication_type_id]')
    select(@disposition_type.name, :from => 'member_note[disposition_type_id]')
    fill_in 'member_note[description]', :with => text_note

    click_on 'Save note'

    assert page.has_content?("The note was added successfuly")

    wait_until {
      within("#operations_table") {
          assert page.has_content?("Note added") 
      }
    }

    wait_until {
      within("#notes") {
        assert page.has_content?(text_note) 
      }
    }
  end


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

  test "show dates according to club timezones" do
    setup_member
    validate_timezone_dates("Eastern Time (US & Canada)")
    validate_timezone_dates("Ekaterinburg")
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
    click_on 'Return to member show'

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


  test "search by last name" do
    setup_search
    active_member = Member.where(:status => 'active').first
    provisional_member = Member.where(:status => 'provisional').first
    lapsed_member = Member.where(:status => 'lapsed').first

    within("#personal_details")do
      wait_until{
        fill_in "member[last_name]", :with => active_member.last_name
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(active_member.full_name)
        assert page.has_content?(active_member.status)
        assert page.has_css?('tr td.ligthgreen')
      }
    end

    within("#personal_details")do
      wait_until{
        fill_in "member[last_name]", :with => provisional_member.last_name
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(provisional_member.full_name)
        assert page.has_content?(provisional_member.status)
        assert page.has_css?('tr td.yellow')
      }
    end

    within("#personal_details")do
      wait_until{
        fill_in "member[last_name]", :with => lapsed_member.last_name
      }
    end
    click_link_or_button 'Search'
    within("#members")do
      wait_until{
        assert page.has_content?(lapsed_member.full_name)
        assert page.has_content?(lapsed_member.status)
        assert page.has_css?('tr td.red')
      }
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
        fill_in "member[state]", :with => member_to_seach.state
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
        fill_in "member[member_id]", :with => @saved_member.visible_id
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
        fill_in "member[state]", :with => @saved_member.state
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

  test "search by external_id" do
    setup_member(false)
    @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
    @member_with_external_id = FactoryGirl.create(:active_member_with_external_id, 
                                                  :club_id => @club_external_id.id, 
                                                  :terms_of_membership => @terms_of_membership_with_gateway,
                                                  :created_by => @admin_agent)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club_external_id.name)
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
        assert page.has_content?(@member_with_external_id.visible_id.to_s)
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
        fill_in "member[state]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
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

  test "create member without information" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
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

  test "create member with invalid characters" do
    setup_member
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'
    within("#table_demographic_information"){
      wait_until{
        fill_in 'member[first_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[address]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[state]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[city]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[last_name]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
        fill_in 'member[zip]', :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
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
        assert page.has_content?("state: is invalid"), "Failure on state validation message"
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
    alert_ok_js
    click_link_or_button 'Create Member'
    within("#error_explanation")do
      wait_until{
        assert page.has_content?("email: is invalid"), "Failure on email validation message"
      }
    end    
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
      assert page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_phone_number, 'Unreachable'

    click_link_or_button "Edit"
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_area_code]', :with => '9876'
      }
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

  test "change unreachable address to undeliverable by changing address" do
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
        fill_in 'member[address]', :with => 'New address name'
      }
    end
    alert_ok_js
    click_link_or_button 'Update Member'
    within("#table_demographic_information")do
      assert !page.has_css?('tr.yellow')
    end 
    @saved_member.reload
    assert_equal @saved_member.wrong_address, nil
  end
end