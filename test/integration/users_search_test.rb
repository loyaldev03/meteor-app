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
    unstubs_elasticsearch_index
    User.index.delete
    User.create_elasticsearch_index
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
    Delayed::Worker.delay_jobs = true
    if create_new_users
      10.times{ create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent }) }
      10.times{ create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) }
      10.times{ create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, { :created_by => @admin_agent }) }
    end
    Delayed::Job.all.each{ |x| x.invoke_job }
    Delayed::Worker.delay_jobs = false

    @search_user = User.first
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  ##########################################################
  # TESTS
  ##########################################################

  # test "search user with empty form" do
  #   setup_search 
  #   visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  #   click_on 'Search'
    
  #   within("#users")do
  #     assert page.has_css?(".pagination")
  #     find("tr", :text => User.last.full_name)
  #   end
  # end

  test "search user by user id" do
    setup_search
    search_user({"user[id]" => "#{@search_user.id}"}, @search_user)
  end

  test "search user by first_name" do
    setup_search
    search_user({"user[first_name]" => "#{@search_user.first_name}"}, @search_user)
    @search_user.update_attribute :first_name, "Darrel Barry"
    @search_user.index.store @search_user
    search_user({"user[first_name]" => "Bar Dar"}, @search_user)
  end

  # Search user with duplicated letters at Last Name
  test "search by last name" do
    setup_search false
    2.times{ create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent }) }
    2.times{ create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, { :created_by => @admin_agent }) }
    2.times{ create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) }
    create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, { :created_by => @admin_agent })
  
    active_user = User.find_by_status 'active'
    provisional_user = User.find_by_status 'provisional'
    lapsed_user = User.find_by_status 'lapsed'
    duplicated_name_user = User.last
    duplicated_name_user.update_attribute(:last_name, "Elwood")
    duplicated_name_user.index.store duplicated_name_user
    search_user({"user[last_name]" => "Elwood"}, duplicated_name_user)
    search_user({"user[last_name]" => active_user.last_name}, active_user)
    within("#users")do
      assert page.has_css?('tr td.btn-success')
    end
    search_user({"user[last_name]" => provisional_user.last_name}, provisional_user)
    within("#users")do
        assert page.has_css?('tr td.btn-warning')
    end
    search_user({"user[last_name]" => lapsed_user.last_name}, lapsed_user)
    within("#users")do
      assert page.has_css?('tr td.btn-danger')
    end
  end

  test "search user by email" do
    setup_search
    search_user({"user[email]" => "#{@search_user.email}"}, @search_user)
    search_user({"user[email]" => "#{@search_user.email.split('@').first}*"}, @search_user)
  end

  test "search user by city" do
    setup_search
    search_user({"user[city]" => "#{@search_user.city}"}, @search_user)
  end

  test "search user by state" do
    setup_search
    user_to_search = User.order("id").last
    search_user({}, user_to_search, user_to_search.country)
  end

  test "search user by user zip" do
    setup_search
    search_user({"user[zip]" => "#{@search_user.zip}"}, @search_user)
  end

  test "search by last digits" do
    setup_search
    cc_last_digits = 8965
    @search_user.active_credit_card.update_attribute :last_digits, cc_last_digits
    @search_user.asyn_elasticsearch_index_without_delay
    within("#payment_details")do
      fill_in "user[cc_last_digits]", :with => cc_last_digits.to_s
    end
    click_link_or_button 'Search'
    within("#users")do
      find("tr", :text => @search_user.full_name)
    end
  end

  test "search by last status" do
    setup_search
    ["provisional", "active", "lapsed"].each do |status|
      user_to_search = User.where("status = ?",status).last
      within("#payment_details")do
        select(status, :from => 'user[status]')
      end
      click_link_or_button 'Search'
      within("#users")do
        find("tr", :text => user_to_search.full_name)
      end
    end
  end

  # TODO: refactor this test. Create one test "go from user index to edit user's" something general. And create
  # one test that validates that "edit user's phone number to a wrong phone number" without using search 
  test "go from user index to edit user's classification to VIP and to Celebrity" do
    setup_user
    ["VIP", "Celebrity"].each do |value|
      search_user({"user[id]" => "#{@saved_user.id}", "user[first_name]" => "#{@saved_user.first_name}", "user[last_name]" => "#{@saved_user.last_name}"}, @saved_user)
      
      within("#users"){ find(".icon-pencil").click }  
      select(value, :from => 'user[member_group_type_id]')
      alert_ok_js
      click_link_or_button 'Update User'
      
      sleep 1
      assert find_field('input_member_group_type').value == value
    end
  end

  test "View token in user record - Admin and Supervisor role" do
    setup_user(false)
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_user.active_credit_card
    ['admin', 'supervisor'].each do |role|
      @admin_agent.update_attribute(:roles, "supervisor")
      visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)

      within("#table_active_credit_card") do
        assert page.has_content?("#{saved_credit_card.token}")
      end
      within(".nav-tabs"){ click_on("Credit Cards") }
      within("#credit_cards") do
        assert page.has_content?("#{saved_credit_card.token}")
      end
    end
  end

  test "View token in user record - Representative rol" do
    setup_user(false)
    unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card,:expire_year => Date.today.year+1)
    @saved_user = create_user(unsaved_user,credit_card,@terms_of_membership_with_gateway.name,false)
    saved_credit_card = @saved_user.active_credit_card
    @admin_agent.update_attribute(:roles, "representative")
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

  # Organize User results by Pagination
  test "search user by pagination" do
    setup_user
    20.times do  
      create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
    end
    30.times do 
      create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, {}, { :created_by => @admin_agent }) 
    end  
    30.times do 
      create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, {}, { :created_by => @admin_agent }) 
    end
    
    visit users_path(:partner_prefix => @club.partner.prefix, :club_prefix => @club.name)
    fill_in 'user[email]', :with => 'a'
    click_on 'Search'
    within(".pagination") do
      assert page.has_content?("1")
      assert page.has_content?("2")
      assert page.has_content?("3")
      assert page.has_content?("4")      
      assert page.has_content?("Next")
    end

    within("#users")do
      begin 
        assert assert page.has_no_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
        assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC").first.full_name)
      end
      click_on("2")
      sleep 2
      begin 
        assert assert page.has_no_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
        assert assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC")[21].full_name)
      end
      click_on("5")
      sleep 2
      begin 
        assert page.has_content?(User.where("club_id = ?", @club.id).order("id DESC").last.full_name)
      end
    end
  end

  test "display user" do
    setup_search
    search_user({"user[id]" => "#{@search_user.id}"}, @search_user)
    page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")

    validate_view_user_base(@search_user, @search_user.status)

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table") { assert page.has_content?(operations_table_empty_text) }

    active_credit_card = @search_user.active_credit_card
    within(".nav-tabs"){ click_on("Credit Cards") }
    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table") { assert page.has_content?(transactions_table_empty_text) }
    within(".nav-tabs"){ click_on("Fulfillments") }
    within("#fulfillments") { assert page.has_content?(fulfillments_table_empty_text) }
    within(".nav-tabs"){ click_on("Communications") }
    within("#communications") { assert page.has_content?(communication_table_empty_text) }
  end

  test "search by multiple values, trimming and also with invalid characters" do
    setup_user
    user_to_search = User.first
    search_user({"user[id]" => "#{user_to_search.id}", "user[first_name]" => user_to_search.first_name, 
                 "user[last_name]" => user_to_search.last_name, "user[email]" => user_to_search.email,
                 "user[city]" => user_to_search.city, "user[zip]" => user_to_search.zip}, user_to_search, user_to_search.country)
    search_user({"user[id]" => "#{user_to_search.id}", "user[first_name]" => "  #{user_to_search.first_name}  ", 
                 "user[last_name]" => "  #{user_to_search.last_name}  ", "user[email]" => "  #{user_to_search.email}  ",
                 "user[city]" => "  #{user_to_search.city}  ", "user[zip]" => "  #{user_to_search.zip}  "}, user_to_search, user_to_search.country)
    # search_user({"user[id]" => "#{user_to_search.id}", "user[first_name]" => "~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*(", 
    #              "user[last_name]" => "~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*(", "user[email]" => "~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*(",
    #              "user[city]" => "~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*(", "user[zip]" => "~!@#$%^&*()_)(*&^%$#@!~!@#$%^&*("}, user_to_search, user_to_search.country, false)
    # within("#users")do
    #   assert page.has_content?('No records were found.')
    # end
  end

  test "search user that does not exist" do
    setup_user
    visit users_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#personal_details")do
      fill_in "user[first_name]", :with => 'Random text'
    end
    click_link_or_button 'Search'
    within("#users")do
      assert page.has_content?('No records were found.')
    end
  end

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
  test "should show status with 'Blisted' on search results, when user is blacklisted." do
    setup_user
    cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
    @saved_user.set_as_canceled!
    @saved_user.update_attribute(:blacklisted,true)

    search_user({"user[id]" => "#{@saved_user.id}"}, @saved_user)
    within("#users")do
      assert page.has_content?("- Blisted")
    end
  end
end