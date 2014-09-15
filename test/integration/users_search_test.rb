require 'test_helper'
 
class UsersSearchTest < ActionController::IntegrationTest

  transactions_table_empty_text = "No data available in table"
  operations_table_empty_text = "No data available in table"
  fulfillments_table_empty_text = "No fulfillments were found"
  communication_table_empty_text = "No communications were found"

  ############################################################
  # SETUP
  ############################################################

  setup do
    unstubs_solr_index
  end

  def setup_user(create_new_user = true)
    @default_state = "Alabama" # when we select options we do it by option text not by value ?
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    if create_new_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, :enrollment_info, {}, { :created_by => @admin_agent })
    end

    sign_in_as(@admin_agent)
   end

  #Only for search test
  def setup_search(create_new_users = true)
    setup_user false
    if create_new_users
      20.times{ create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) }
      30.times{ create_active_user(@terms_of_membership_with_gateway, :provisional_user, nil, {}, { :created_by => @admin_agent }) }
    end
    @search_user = User.first
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  ##########################################################
  # TESTS
  ##########################################################

  # test "Search users by token - Admin rol" do
  #   setup_user(false)
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
  #   @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
  #   saved_credit_card = @saved_user.active_credit_card
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   fill_in "user[cc_token]", :with => saved_credit_card.token
  #   click_on 'Search'
  #   assert page.has_content?("#{unsaved_user.first_name}")
  # end 

  # test "Bill date filter" do
  #   setup_user(false)
  #   unsaved_user=FactoryGirl.build(:user_with_api, :club_id => @club.id)
  #   unsaved_user_2=FactoryGirl.build(:user_with_api, :club_id => @club.id)
  #   credit_cardd=FactoryGirl.build(:credit_card_american_express)
  #   c = create_user(unsaved_user, credit_cardd)
  #   c2 = create_user(unsaved_user_2)
  #   tran_1 = FactoryGirl.create(:transaction, :user_id => c.id)
  #   tran_1.update_attribute(:created_at, Time.zone.now + 10.days)
  #   tran_2 = FactoryGirl.create(:transaction, :user_id => c2.id)
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

  #   select_from_datepicker("user_billing_date_start", Time.zone.now+9.days)
  #   select_from_datepicker("user_billing_date_end", Time.zone.now+11.days)
 
  #   click_link_or_button('Search')
  #     within("#users") do
  #     assert find("tr", :text => c.full_name)
  #     assert page.has_no_content? c2.full_name
  #   end
  # end

  # TODO: refactor this test. Create one test "go from user index to edit user's" something general. And create
  # one test that validates that "edit user's phone number to a wrong phone number" without using search 
  # test "go from user index to edit user's phone number to a wrong phone number" do
  #   setup_user
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#personal_details")do
  #     fill_in 'user[phone_country_code]', :with => @saved_user.phone_country_code
  #     fill_in 'user[phone_area_code]', :with => @saved_user.phone_area_code
  #     fill_in 'user[phone_local_number]', :with => @saved_user.phone_local_number
  #   end
  #   click_link_or_button 'Search'
  #   within("#users"){ find(".icon-pencil").click }
  #   within("#table_contact_information")do
  #     fill_in 'user[phone_country_code]', :with => 'TYUIYTRTYUYT'
  #     fill_in 'user[phone_area_code]', :with => 'TYUIYTRTYUYT'
  #     fill_in 'user[phone_local_number]', :with => 'TYUIYTRTYUYT'
  #   end
  #   alert_ok_js
  #   click_link_or_button 'Update User'
  #   within("#error_explanation")do
  #     assert page.has_content?('phone_country_code: is not a number')
  #     assert page.has_content?('phone_area_code: is not a number')
  #     assert page.has_content?('phone_local_number: is not a number')
  #   end
  # end

  # TODO: refactor this test. Create one test "go from user index to edit user's" something general. And create
  # one test that validates that "edit user's phone number to a wrong phone number" without using search 
  # test "go from user index to edit user's type of phone number to home type" do
  #   setup_user
  #   @saved_user.update_attribute(:type_of_phone_number, 'mobile')

  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#personal_details")do
  #     fill_in 'user[phone_country_code]', :with => @saved_user.phone_country_code
  #     fill_in 'user[phone_area_code]', :with => @saved_user.phone_area_code
  #     fill_in 'user[phone_local_number]', :with => @saved_user.phone_local_number
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find(".icon-pencil").click
  #   end   
  #   within("#table_contact_information")do
  #     assert find_field('user[type_of_phone_number]').value == @saved_user.type_of_phone_number
  #     assert find_field('user[phone_country_code]').value == @saved_user.phone_country_code.to_s
  #     assert find_field('user[phone_area_code]').value == @saved_user.phone_area_code.to_s
  #     assert find_field('user[phone_local_number]').value == @saved_user.phone_local_number.to_s
  #     select('Home', :from => 'user[type_of_phone_number]' )
  #   end
  #   alert_ok_js
  #   click_link_or_button 'Update User'
  #   within("#table_contact_information")do
  #     @saved_user.reload
  #     assert page.has_content?(@saved_user.full_phone_number)
  #     assert page.has_content?(@saved_user.type_of_phone_number.capitalize)
  #   end
  # end

  # TODO: refactor this test. Create one test "go from user index to edit user's" something general. And create
  # one test that validates that "edit user's phone number to a wrong phone number" without using search 
  # test "go from user index to edit user's type of phone number to other type" do
  #   setup_user

  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#personal_details")do
  #     fill_in 'user[phone_country_code]', :with => @saved_user.phone_country_code
  #     fill_in 'user[phone_area_code]', :with => @saved_user.phone_area_code
  #     fill_in 'user[phone_local_number]', :with => @saved_user.phone_local_number
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find(".icon-pencil").click
  #   end   
  #   within("#table_contact_information")do
  #     assert find_field('user[type_of_phone_number]').value == @saved_user.type_of_phone_number
  #     assert find_field('user[phone_country_code]').value == @saved_user.phone_country_code.to_s
  #     assert find_field('user[phone_area_code]').value == @saved_user.phone_area_code.to_s
  #     assert find_field('user[phone_local_number]').value == @saved_user.phone_local_number.to_s
  #     select('Other', :from => 'user[type_of_phone_number]' )
  #   end
  #   alert_ok_js
  #   click_link_or_button 'Update User'

  #   within("#table_contact_information")do
  #     assert page.has_content?(@saved_user.full_phone_number)
  #     assert page.has_content?('Other')
  #   end
  # end

  # TODO: refactor this test. Create one test "go from user index to edit user's" something general. And create
  # one test that validates that "edit user's phone number to a wrong phone number" without using search 
  # test "go from user index to edit user's classification to VIP and to Celebrity" do
  #   setup_user
  #   ["VIP", "Celebrity"].each do |value|
  #     visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #     within("#personal_details") do
  #       fill_in 'user[id]', :with => @saved_user.id.to_s
  #       fill_in 'user[first_name]', :with => @saved_user.first_name
  #       fill_in 'user[last_name]', :with => @saved_user.last_name
  #     end
  #     click_link_or_button 'Search'
  #     within("#users"){ find(".icon-pencil").click }  
  #     select(value, :from => 'user[member_group_type_id]')

  #     alert_ok_js
  #     click_link_or_button 'Update User'

  #     assert find_field('input_member_group_type').value == value
  #   end
  # end

  # test "Search users by token - Supervisor rol" do
  #   setup_user(false)
  #   @admin_agent.update_attribute(:roles,["supervisor"])
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
  #   @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
  #   saved_credit_card = @saved_user.active_credit_card
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   fill_in "user[cc_token]", :with => saved_credit_card.token
  #   click_on 'Search'
  #   assert page.has_content?("#{unsaved_user.first_name}")
  # end 

  # test "Search users by token - Representative rol" do
  #   setup_user(false)
  #   @admin_agent.update_attribute(:roles,["representative"])
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
  #   @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
  #   saved_credit_card = @saved_user.active_credit_card
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   assert has_no_content?("CC Token")
  # end 

  # test "View token in user record - Admin rol" do
  #   setup_user(false)
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
  #   @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
  #   saved_credit_card = @saved_user.active_credit_card
  #   visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
  #   within("#table_active_credit_card") do
  #     assert page.has_content?("#{saved_credit_card.token}")
  #   end
  #   within(".nav-tabs"){ click_on("Credit Cards") }
  #   within("#credit_cards") do
  #   assert page.has_content?("#{saved_credit_card.token}")
  #   end
  # end 

  # test "View token in user record - Supervisor rol" do
  #   setup_user(false)
  #   @admin_agent.update_attribute(:roles,["supervisor"])
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
  #   credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
  #   @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
  #   saved_credit_card = @saved_user.active_credit_card
  #   visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
  #   within("#table_active_credit_card") do
  #     assert page.has_content?("#{saved_credit_card.token}")
  #   end
  #   within(".nav-tabs"){ click_on("Credit Cards") }
  #   within("#credit_cards") do
  #   assert page.has_content?("#{saved_credit_card.token}")
  #   end
  # end 

  test "View token in user record - Representative rol" do
    setup_user(false)
    @admin_agent.update_attribute(:roles,["representative"])
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_user.active_credit_card
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    assert has_no_content?("CC Token")
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_active_credit_card") do
      assert page.has_no_content?("#{saved_credit_card.token}")
    end
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") do
    assert page.has_no_content?("#{saved_credit_card.token}")
    end
  end 

  # test "search users by next bill date" do
  #   setup_search
  #   @search_user.update_attribute :next_retry_bill_date, Time.zone.now.utc+7.days
  #   page.execute_script("window.jQuery('#user_next_retry_bill_date').next().click()")
  #   within("#ui-datepicker-div") do
  #     click_on("#{@search_user.next_retry_bill_date.day}")
  #   end
  #   search_user("user[next_retry_bill_date]", nil, @search_user)
  # end

  # test "search user by user id" do
  #   setup_search
  #   search_user("user[id]", "#{@search_user.id}", @search_user)
  # end

  # test "search user by first name" do
  #   setup_search
  #   search_user("user[first_name]","#{@search_user.first_name}", @search_user)
  # end

  # test "search user with empty form" do
  #   setup_search 
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   click_on 'Search'
    
  #   within("#users")do
  #     assert page.has_css?(".pagination")
  #     find("tr", :text => User.last.full_name)
  #   end
  # end

  # Organize User results by Pagination
  # test "search user by pagination" do
  #   setup_user
  #   20.times do  
  #     create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
  #     sleep 0.5
  #   end
  #   30.times do 
  #     create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) 
  #     sleep 0.5
  #   end  
  #   30.times do 
  #     create_active_user(@terms_of_membership_with_gateway, :provisional_user, nil, {}, { :created_by => @admin_agent }) 
  #     sleep 0.5
  #   end

  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   click_on 'Search'
    
  #   within(".pagination") do
  #     assert page.has_content?("1")
  #     assert page.has_content?("2")
  #     assert page.has_content?("3")
  #     assert page.has_content?("4")      
  #     assert page.has_content?("Next")
  #   end

  #   within("#users")do
  #     begin 
  #       assert assert page.has_no_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
  #       assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC").first.full_name)
  #     end
  #     click_on("2")
  #     begin 
  #       assert assert page.has_no_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
  #       assert assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC")[40].full_name)
  #     end
  #     click_on("3")
  #     begin 
  #       assert assert page.has_no_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
  #       assert assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC")[70].full_name)
  #     end
  #     click_on("4")
  #     begin 
  #       assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
  #     end
  #   end
  # end

  # test "search an user with next bill date in past" do
  #   setup_search
  #   page.execute_script("window.jQuery('#user_next_retry_bill_date').next().click()")
  #   assert page.evaluate_script("window.jQuery('.ui-datepicker-prev').is('.ui-state-disabled')")
  # end

  # test "display user" do
  #   setup_search
  #   search_user("user[id]", "#{@search_user.id}", @search_user)
  #   within("#users") do
  #     assert page.has_content?("#{@search_user.id}")
  #   end
  #   page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")

  #   validate_view_user_base(@search_user, @search_user.status)

  #   within(".nav-tabs"){ click_on("Operations") }
  #   within("#operations_table") { assert page.has_content?(operations_table_empty_text) }

  #   active_credit_card = @search_user.active_credit_card
  #   within(".nav-tabs"){ click_on("Credit Cards") }
  #   within("#credit_cards") { 
  #     assert page.has_content?("#{active_credit_card.number}") 
  #     assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
  #   }

  #   within(".nav-tabs"){ click_on("Transactions") }
  #   within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
  #   within(".nav-tabs"){ click_on("Fulfillments") }
  #   within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }
  #   within(".nav-tabs"){ click_on("Communications") }
  #   within("#communications") { assert page.has_content?(communication_table_empty_text) }
  # end

  #Search user with duplicated letters at Last Name
  # test "search by last name" do
  #   setup_search false
  #   2.times{ create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent }) }
  #   2.times{ create_active_user(@terms_of_membership_with_gateway, :provisional_user, nil, {}, { :created_by => @admin_agent }) }
  #   2.times{ create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) }
  #   create_active_user(@terms_of_membership_with_gateway, :provisional_user, nil, {}, { :created_by => @admin_agent })
  
  #   active_user = User.find_by_status 'active'
  #   provisional_user = User.find_by_status 'provisional'
  #   lapsed_user = User.find_by_status 'lapsed'
  #   duplicated_name_user = User.last
  #   duplicated_name_user.update_attribute(:last_name, "Elwood")

  #   within("#personal_details"){ fill_in "user[last_name]", :with => "Elwood" }

  #   click_link_or_button 'Search'
  #   within("#users"){ assert page.has_content?(duplicated_name_user.full_name) }

  #   within("#personal_details"){ fill_in "user[last_name]", :with => active_user.last_name }
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(active_user.full_name)
  #     assert page.has_content?(active_user.status)
  #     assert page.has_css?('tr td.btn-success')
  #   end

  #   within("#personal_details"){ fill_in "user[last_name]", :with => provisional_user.last_name }
  #   click_link_or_button 'Search'
  #   within("#users")do
  #       assert page.has_content?(provisional_user.full_name)
  #       assert page.has_content?(provisional_user.status)
  #       assert page.has_css?('tr td.btn-warning')
  #   end

  #   within("#personal_details"){ fill_in "user[last_name]", :with => lapsed_user.last_name }
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(lapsed_user.full_name)
  #     assert page.has_content?(lapsed_user.status)
  #     assert page.has_css?('tr td.btn-danger')
  #   end
  # end

  # test "search by email" do
  #   setup_search
  #   user_to_seach = User.first

  #   within("#personal_details")do
  #     fill_in "user[email]", :with => user_to_seach.email
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "search by phone number" do
  #   setup_search
  #   user_to_seach = User.last
  #   within("#personal_details")do
  #     fill_in "user[phone_country_code]", :with => user_to_seach.phone_country_code
  #     fill_in "user[phone_area_code]", :with => user_to_seach.phone_area_code
  #     fill_in "user[phone_local_number]", :with => user_to_seach.phone_local_number
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "search by address" do
  #   setup_search
  #   user_to_seach = User.first
  #   within("#contact_details")do
  #     fill_in "user[address]", :with => user_to_seach.address
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "search by city" do
  #   setup_search
  #   user_to_seach = User.first
  #   within("#contact_details")do
  #     fill_in "user[city]", :with => user_to_seach.city
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "search by state" do
  #   setup_search
  #   user_to_seach = User.last
  #   within("#contact_details")do
  #     select_country_and_state(user_to_seach.country)
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "search by zip" do
  #   setup_search
  #   user_to_seach = User.first
  #   within("#contact_details")do
  #     fill_in "user[zip]", :with => user_to_seach.zip
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => user_to_seach.full_name)
  #   end
  # end

  # test "Searching zip with partial digits" do
  #   setup_search
  #   user_to_seach = User.first
  #   user_to_seach.update_attribute(:zip, 12345)
  #   within("#contact_details")do
  #     fill_in "user[zip]", :with => "12"
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(user_to_seach.full_name)
  #   end

  #   within("#contact_details")do
  #     fill_in "user[zip]", :with => "34"
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(user_to_seach.full_name)
  #   end

  #   within("#contact_details")do
  #     fill_in "user[zip]", :with => "45"
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(user_to_seach.full_name)
  #   end
  # end

  # test "search by last digits" do
  #   setup_search
  #   @search_user.active_credit_card.update_attribute :last_digits, 8965
  #   within("#payment_details")do
  #     fill_in "user[last_digits]", :with => @search_user.active_credit_card.last_digits
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     find("tr", :text => @search_user.full_name)
  #   end
  # end

  # test "search by notes" do
  #   setup_user
  #   user_note = FactoryGirl.create(:user_note, :user_id => @saved_user.id, 
  #                                    :created_by_id => @admin_agent.id,
  #                                    :communication_type_id => @communication_type.id,
  #                                    :disposition_type_id => @disposition_type.id)
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   within("#payment_details")do
  #       fill_in "user[notes]", :with => @saved_user.user_notes.first.description
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #       assert page.has_content?(@saved_user.full_name)
  #   end
  # end

  # test "search by multiple values" do
  #   setup_user
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   user_note = FactoryGirl.create(:user_note, :user_id => @saved_user.id, 
  #                                    :created_by_id => @admin_agent.id,
  #                                    :communication_type_id => @communication_type.id,
  #                                    :disposition_type_id => @disposition_type.id)
  #   user_to_seach = User.first
  #   within("#personal_details")do
  #     fill_in "user[id]", :with => @saved_user.id
  #     fill_in "user[first_name]", :with => @saved_user.first_name
  #     fill_in "user[last_name]", :with => @saved_user.last_name
  #     fill_in "user[email]", :with => @saved_user.email
  #     fill_in "user[phone_country_code]", :with => @saved_user.phone_country_code
  #     fill_in "user[phone_area_code]", :with => @saved_user.phone_area_code
  #     fill_in "user[phone_local_number]", :with => @saved_user.phone_local_number
  #   end
  #   within("#contact_details")do
  #     fill_in "user[city]", :with => @saved_user.city
  #     select_country_and_state(@saved_user.country)
  #     fill_in "user[address]", :with => @saved_user.address
  #     fill_in "user[zip]", :with => @saved_user.zip
  #   end
  #   page.execute_script("window.jQuery('#user_next_retry_bill_date').next().click()")
  #   within("#ui-datepicker-div") do
  #     click_on("#{Time.zone.now.day}")
  #   end
  #   within("#payment_details")do
  #     fill_in "user[last_digits]", :with => @saved_user.active_credit_card.last_digits
  #     fill_in "user[notes]", :with => @saved_user.user_notes.first.description
  #   end

  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(@saved_user.full_name)
  #   end
  # end

  # test "Trim texts when searching" do
  #   setup_user
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   user_note = FactoryGirl.create(:user_note, :user_id => @saved_user.id, 
  #                                      :created_by_id => @admin_agent.id,
  #                                      :communication_type_id => @communication_type.id,
  #                                      :disposition_type_id => @disposition_type.id)
  #   user_to_seach = User.first
  #   within("#personal_details")do
  #     fill_in "user[id]", :with => " #{@saved_user.id} "
  #     fill_in "user[first_name]", :with => " #{@saved_user.first_name} "
  #     fill_in "user[last_name]", :with => " #{@saved_user.last_name} "
  #     fill_in "user[email]", :with => " #{@saved_user.email} "
  #     fill_in "user[phone_country_code]", :with => " #{@saved_user.phone_country_code} "
  #     fill_in "user[phone_area_code]", :with => " #{@saved_user.phone_area_code} "
  #     fill_in "user[phone_local_number]", :with => " #{@saved_user.phone_local_number} "
  #   end
  #   within("#contact_details")do
  #     fill_in "user[city]", :with => " #{@saved_user.city} "
  #     select_country_and_state(@saved_user.country)
  #     fill_in "user[address]", :with => " #{@saved_user.address} "
  #     fill_in "user[zip]", :with => " #{@saved_user.zip} "
  #   end
  #   page.execute_script("window.jQuery('#user_next_retry_bill_date').next().click()")
  #   within("#ui-datepicker-div") do
  #     click_on("#{Time.zone.now.day}")
  #   end
  #   within("#payment_details")do
  #     fill_in "user[last_digits]", :with => " #{@saved_user.active_credit_card.last_digits} "
  #     fill_in "user[notes]", :with => " #{@saved_user.user_notes.first.description} "
  #   end

  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?(@saved_user.full_name)
  #   end
  # end

  # test "search by external_id" do
  #   setup_user(false)    
  #   @club_external_id = FactoryGirl.create(:simple_club_with_require_external_id, :partner_id => @partner.id)
  #   @terms_of_membership_with_gateway_and_external_id = FactoryGirl.create(:terms_of_membership_with_gateway_and_external_id, :club_id => @club_external_id.id)
    
  #   unsaved_user = FactoryGirl.build(:user_with_api)
  #   credit_card = FactoryGirl.build(:credit_card)
  #   enrollment_info = FactoryGirl.build(:enrollment_info)
  #   create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway_and_external_id, false)
  #   @user_with_external_id = User.find_by_email unsaved_user.email     
    
  #   visit users_path(:partner_prefix => @user_with_external_id.club.partner.prefix, :club_prefix => @user_with_external_id.club.name)
  #   assert_equal @club_external_id.requires_external_id, true, "Club does not have require external id"
  #   within("#personal_details")do
  #     fill_in "user[external_id]", :with => @user_with_external_id.external_id
  #   end
  #   click_link_or_button 'Search'

  #   within("#users")do
  #     assert page.has_content?(@user_with_external_id.status)
  #     assert page.has_content?(@user_with_external_id.id.to_s)
  #     assert page.has_content?(@user_with_external_id.external_id.to_s)
  #     assert page.has_content?(@user_with_external_id.full_name)
  #     assert page.has_content?(@user_with_external_id.full_address)
  #   end
  # end

  # test "search user by invalid characters" do
  #   setup_user
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   user_note = FactoryGirl.create(:user_note, :user_id => @saved_user.id, 
  #                                    :created_by_id => @admin_agent.id,
  #                                    :communication_type_id => @communication_type.id,
  #                                    :disposition_type_id => @disposition_type.id)
  #   user_to_seach = User.first
  #   within("#personal_details")do
  #     fill_in "user[id]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #     fill_in "user[first_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #     fill_in "user[last_name]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #     fill_in "user[email]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #   end
  #   within("#contact_details")do
  #     fill_in "user[city]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #     fill_in "user[address]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #     fill_in "user[zip]", :with => '~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*('
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?('No records were found.')
  #   end
  # end

  # test "search user that does not exist" do
  #   setup_user
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   user_note = FactoryGirl.create(:user_note, :user_id => @saved_user.id, 
  #                                    :created_by_id => @admin_agent.id,
  #                                    :communication_type_id => @communication_type.id,
  #                                    :disposition_type_id => @disposition_type.id)
  #   user_to_seach = User.first
  #   within("#personal_details")do
  #     fill_in "user[first_name]", :with => 'Random text'
  #   end

  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?('No records were found.')
  #   end
  # end

  # test "search user need needs_approval" do
  #   @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
  #   @partner = FactoryGirl.create(:partner)
  #   @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
  #   @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
  #   Time.zone = @club.time_zone 

  #   @saved_user = create_active_user(@terms_of_membership_with_gateway_needs_approval, :applied_user, :enrollment_info, {}, { :created_by => @admin_agent })

  #   sign_in_as(@admin_agent)
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)

  #   user_to_seach = User.first
  #   within("#personal_details")do
  #     check('user[needs_approval]')
  #   end
  #   click_link_or_button 'Search'
  #   within("#users")do
  #     assert page.has_content?("#{@saved_user.full_name}")
  #   end
  # end

  test "should accept applied user" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
        
    unsaved_user = FactoryGirl.build(:user_with_api)
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway_needs_approval, false)
    @saved_user = User.find_by_email unsaved_user.email
    
    sign_in_as(@admin_agent)
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)

    confirm_ok_js
    click_link_or_button 'Approve'
    assert find_field('input_first_name').value == @saved_user.first_name
 
    within("#table_membership_information") do  
      within("#td_mi_status") { assert page.has_content?('provisional') }
    end
    
  end

  test "should reject applied user" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway_needs_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    Time.zone = @club.time_zone 
    
    unsaved_user = FactoryGirl.build(:user_with_api)
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway_needs_approval, false)
    @saved_user = User.find_by_email unsaved_user.email

    sign_in_as(@admin_agent)
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
	
    confirm_ok_js
    click_link_or_button 'Reject'

    assert find_field('input_first_name').value == @saved_user.first_name

    @saved_user.reload
    within("#table_membership_information") do  
      within("#td_mi_status") { assert page.has_content?('lapsed') }
    end
  end

  # test "create user without gender" do
  #   setup_user(false)
  #   unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id, :gender => "")
  #   @saved_user = create_user(unsaved_user)
  #   assert find_field('user_gender').value == ''
  # end

  test "create user without type of phone number" do
    setup_user(false)

    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    unsaved_user.type_of_phone_number = ''
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    create_user(unsaved_user,nil, nil, true)
    @saved_user = User.find_by_email(unsaved_user.email)
    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    assert_equal(@saved_user.type_of_phone_number, '')
  end

  test "canceled date will be abble to be cancelled once set." do
    setup_user
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

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
    click_link_or_button 'Cancel user'
    
    @saved_user.reload
    assert find_field('input_first_name').value == @saved_user.first_name
    assert page.has_content?("Member cancellation scheduled to #{I18n.l(@saved_user.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}") 

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
    click_link_or_button 'Cancel user'
		@saved_user.reload
    find(".alert", :text => "Member cancellation scheduled to #{I18n.l(@saved_user.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}" )
    assert page.has_content? "Member cancellation scheduled to #{I18n.l(@saved_user.cancel_date, :format => :only_date)} - Reason: #{cancel_reason.name}"
  end

  # See an user is blacklisted in the search results
  # test "should show status with 'Blisted' on search results, when user is blacklisted." do
  #   setup_user
  #   cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
  #   @saved_user.set_as_canceled!
  #   @saved_user.update_attribute(:blacklisted,true)

  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
  #   click_link_or_button 'Search'

  #   within("#users")do
  #     assert page.has_content?("- Blisted")
  #   end
  # end
end