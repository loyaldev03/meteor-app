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
      
      within("#td_mi_status") { assert page.has_content?(member.status) }
      
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

  def fill_in_member(unsaved_member, credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select(unsaved_member.gender, :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select(unsaved_member.country_name, :from => 'member[country]')
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
        select(unsaved_member.type_of_phone_number, :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'  	
  end

  def generate_operations(member)
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 100, :description => 'Member was enrolled' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 200, :description => 'Blacklisted member. Reason: Too much spam' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 201, :description => 'Blacklisted member. Reason: dont like it' )
  	FactoryGirl.create(:operation_profile, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 202, :description => 'Blacklisted member. Reason: testing' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 300, :description => 'Communication sent successfully' )
  	FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 301, :description => 'Communication was not sent' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 1000, :description => 'Member updated successfully' )
 		FactoryGirl.create(:operation_other, :created_by_id => @admin_agent.id, :resource_type => 'Member',
  										 :member_id => member.id, :operation_type => 1000, :description => 'Member was recovered' )
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
	  	select('United States', :from => 'member[country]')
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

    within("#td_mi_status") { assert page.has_content?("provisional") }
      
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
        select('United States', :from => 'member[country]')
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

  test "show terms of memberhip" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button("#{@saved_member.terms_of_membership.name}")
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
        assert page.has_content?('Test welcome')
        assert page.has_content?('Test active')
        assert page.has_content?('Test cancellation')
        assert page.has_content?('Test prebill ')
        assert page.has_content?('Test prebill_renewal')
        assert page.has_content?('Test refund')
        assert page.has_content?('Test birthday')
        assert page.has_content?('Test pillar')
      }
    end
  end

  test "return to member's profile from terms of membership" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_link_or_button("#{@saved_member.terms_of_membership.name}")
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
        assert page.has_content?('Test welcome')
        assert page.has_content?('Test active')
        assert page.has_content?('Test cancellation')
        assert page.has_content?('Test prebill ')
        assert page.has_content?('Test prebill_renewal')
        assert page.has_content?('Test refund')
        assert page.has_content?('Test birthday')
        assert page.has_content?('Test pillar')
      }
    end
    click_link_or_button('Return to member show')
    wait_until{
      assert find_field('input_visible_id').value == "#{@saved_member.visible_id}"
      assert find_field('input_first_name').value == @saved_member.first_name
      assert find_field('input_last_name').value == @saved_member.last_name
      assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')
      assert find_field('input_member_group_type').value == (@saved_member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : @saved_member.member_group_type.name)
    }
  end

  test "create member with gender male" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('M', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
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
        select(unsaved_member.type_of_phone_number,:from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    wait_until{
      assert find_field('input_gender').value == ('Male')
    }
  end

  test "create member with gender female" do
    setup_member
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('F', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
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
        select(unsaved_member.type_of_phone_number,:from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    wait_until{
      assert find_field('input_first_name').value == unsaved_member.first_name
    }
    wait_until{
      assert find_field('input_gender').value == ('Female')
    }
  end

  test "change type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.type_of_phone_number)
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
        assert page.has_content?(@saved_member.type_of_phone_number)
      }
    end
  end

  test "create member with phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    


    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('M', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
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
        select(unsaved_member.type_of_phone_number,:from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'
    wait_until{
      assert find_field('input_first_name').value == unsaved_member.first_name
    }
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?("#{unsaved_member.full_phone_number}")
      }
    end
  end

  test "create member without phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information") do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('M', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
        fill_in 'member[city]', :with => unsaved_member.city
        fill_in 'member[last_name]', :with => unsaved_member.last_name
        fill_in 'member[zip]', :with => unsaved_member.zip
      }
    end
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'

    within("#error_explanation")do
      wait_until{
        assert page.has_content?("phone_country_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_country_code validation message"
        assert page.has_content?("phone_area_code: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
        assert page.has_content?("phone_local_number: can't be blank,is not a number,is too short (minimum is 1 characters)"), "Failure on phone_area_code validation message"
      }
    end
  end

  test "should create member and display type of phone number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('M', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
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
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'

    member = Member.find_by_email(unsaved_member.email)
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(unsaved_member.type_of_phone_number)
      }
    end

  end

  test "edit member's type of phone number" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(@saved_member.type_of_phone_number)
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
    assert_equal Member.last.type_of_phone_number, 'Mobile'
  end

  test "create member with 'home' telephone type" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select('M', :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        fill_in 'member[state]', :with => unsaved_member.state
        select('United States', :from => 'member[country]')
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
        select('Home', :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'

    member = Member.find_by_email(unsaved_member.email)
    within("#table_contact_information")do
      wait_until{
        assert page.has_content?(unsaved_member.full_phone_number)
        assert page.has_content?('Home')
      }
    end
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
    @saved_member.type_of_phone_number = 'Mobile'
    @saved_member.save

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
        assert page.has_content?(@saved_member.type_of_phone_number)
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

  test "create member with canadian zip" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent,
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'Quebec',
                                         :zip => 'H3G 1M8',
                                         :country => 'CA')
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)
    wait_until{
      assert find_field('input_first_name').value == unsaved_member.first_name
    }
    saved_member = Member.find_by_email(unsaved_member.email)

    assert find_field('input_visible_id').value == saved_member.visible_id.to_s
    assert find_field('input_first_name').value == saved_member.first_name
    assert find_field('input_last_name').value == saved_member.last_name
    assert find_field('input_gender').value == (saved_member.gender == 'F' ? 'Female' : 'Male')
    assert find_field('input_member_group_type').value == (saved_member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : saved_member.member_group_type.name)
  end

  test "create member with invalid canadian zip" do
  	setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent,
                                         :address => '1455 De Maisonneuve Blvd. W. Montreal',
                                         :state => 'Quebec',
                                         :zip => '%^tYU2123',
                                         :country => 'CA')
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)

    within('#error_explanation')do
    	wait_until{
    		assert page.has_content?('zip: The zip code is not valid for the selected country.')
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
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member(unsaved_member,credit_card)

    wait_until{
      assert find_field('input_first_name').value == unsaved_member.first_name
    }

    saved_member = Member.find_by_email(unsaved_member.email)
    generate_operations(saved_member)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => saved_member.visible_id)

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
    10.times{FactoryGirl.create(:operation_communication, :created_by_id => @admin_agent.id, 
                                :resource_type => 'Member', :member_id => @saved_member.id, 
                                :description => 'Member updated succesfully last' )
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    sleep(2) #Wait to the profile.
    within("#operations_table")do
      wait_until{
        assert page.has_content?('Member updated succesfully last')
      }
    end
  end

  test "see operations grouped by billing from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
      }
    end
  end

  test "see operations grouped by profile from lastest to newest" do
    setup_member
    generate_operations(@saved_member)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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

    within("#dataTableSelect")do
      wait_until{
        select('others', :from => 'operation[operation_type]')
      }
    end
    within("#operations_table")do
      wait_until{
        assert page.has_content?('Member was updated successfully - 1000')
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

  test "create a member with an expired credit card" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => 2011)
    
    fill_in_member(unsaved_member,credit_card)

    within("#error_explanation")do
      wait_until{
        assert page.has_content?('Credit card is invalid or is expired!')
      }
    end
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

  test "create member without gender" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent,
                                         :gender => '')

    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => 2011)
    
    fill_in_member(unsaved_member,credit_card)

    within("#error_explanation")do
      wait_until{
        assert page.has_content?("gender: can't be blank")
      }
    end
  end

  test "create member without type of type_of_phone_number" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id, 
                                         :terms_of_membership => @terms_of_membership_with_gateway,
                                         :created_by => @admin_agent,
                                         :type_of_phone_number => '')

    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => 2011)
    
    fill_in_member(unsaved_member,credit_card)

    within("#error_explanation")do
      wait_until{
        assert page.has_content?("type_of_phone_number: can't be blank,is not included in the list")
      }
    end
  end

  test "display member with blank product_sku." do
    setup_member
    enrollment_info = FactoryGirl.create(:enrollment_info, :product_sku => '', :member_id => @saved_member.id)
    @saved_member.set_as_canceled!
    @saved_member.recovered

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
      assert find_field('input_last_name').value == @saved_member.last_name
      assert find_field('input_gender').value == (@saved_member.gender == 'F' ? 'Female' : 'Male')
      assert find_field('input_member_group_type').value == (@saved_member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : @saved_member.member_group_type.name)
    }
  end

  test "search member need needs_approval" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
    @saved_member = FactoryGirl.create(:applied_member, :club_id => @club.id, 
                                       :terms_of_membership => @terms_of_membership_with_gateway_needs_approval,
                                       :created_by => @admin_agent)
    @saved_member.reload

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
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
    @saved_member = FactoryGirl.create(:applied_member, :club_id => @club.id, 
                                       :terms_of_membership => @terms_of_membership_with_gateway_needs_approval,
                                       :created_by => @admin_agent)
    @enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => @saved_member.id)

    @saved_member.reload

    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

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
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
    @saved_member = FactoryGirl.create(:applied_member, :club_id => @club.id, 
                                       :terms_of_membership => @terms_of_membership_with_gateway_needs_approval,
                                       :created_by => @admin_agent)
    @enrollment_info = FactoryGirl.create(:enrollment_info, :member_id => @saved_member.id)

    @saved_member.reload

    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

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

end