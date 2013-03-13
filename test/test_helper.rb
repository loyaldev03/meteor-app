ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start 'rails'

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/dsl'
require 'database_cleaner'
require 'mocha/setup'

DatabaseCleaner.strategy = :truncation
# require 'capybara-webkit'

#Capybara.javascript_driver = :webkit
# capybara levanta un server por default
# Capybara.server_port = '8000'
# apybara.app_host = 'http://localhost:8000'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  CREDIT_CARD_TOKEN = { nil => "c25ccfecae10384698a44360444dea", "4012301230123010" => "c25ccfecae10384698a44360444dead8", 
    "5589548939080095" => "c25ccfecae10384698a44360444dead7",
    "340504323632976" => "c25ccfecae10384698a44360444dead6", "123456" => "anytransactioniditsvalid.forinvalidccnumber", 
    "123456789" => "c25ccfecae10384698asddd60444dead6" }


  def active_merchant_stubs(code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, 
      { "transaction_id"=>"c25ccfecae10384698a44360444dead8", "error_code"=> code, 
       "auth_response_text"=>"No Match", "avs_result"=>"N", "auth_code"=>"T5768H" }, 
      { "code"=>"N", "message"=>"Street address and postal code do not match.", 
        "street_match"=>"N", "postal_match"=>"N" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:refund).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:credit).returns(answer)
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end
  def active_merchant_stubs_store(number = nil, code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { "transaction_id"=>CREDIT_CARD_TOKEN[number], "error_code"=> code, "auth_response_text"=>"No Match" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:store).returns(answer)
  end
  def active_merchant_stubs_purchace(number = nil, code = "000", message = "This transaction has been approved with stub", success = true)
    answer = ActiveMerchant::Billing::Response.new(success, message, { "transaction_id"=>CREDIT_CARD_TOKEN[number], "error_code"=> code, "auth_response_text"=>"No Match" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
  end

  def create_active_member(tom, member_type = :active_member, enrollment_type = :enrollment_info, member_args = {}, membership_args = {}, use_default_active_merchant_stub = true)
    if use_default_active_merchant_stub
      active_merchant_stubs 
      active_merchant_stubs_store
    end
    membership = FactoryGirl.create("#{member_type}_membership".to_sym, { terms_of_membership: tom }.merge(membership_args))
    active_member = FactoryGirl.create(member_type, { club: tom.club, current_membership: membership }.merge(member_args))
    active_member.memberships << membership
    active_member.save
    ei = FactoryGirl.create(enrollment_type, :member_id => active_member.id) unless enrollment_type.nil?
    membership.enrollment_info = ei
    active_member.reload
    active_member
  end  

end

class ActionController::TestCase
  include Devise::TestHelpers
end

module ActionController
  class IntegrationTest
    include Capybara::DSL

    self.use_transactional_fixtures = false # DOES WORK! Damn it!
  
    #setup do
    #  Capybara.current_driver = :selenium
    #  DatabaseCleaner.start
    #end

    def init_test_setup
      DatabaseCleaner.start
      Capybara.current_driver = :selenium
      #Capybara.current_driver = :webkit
      #Capybara.javascript_driver = nil
      Capybara.default_wait_time = 10
    end

    def sign_in_as(user)
      visit '/'
      fill_in 'agent_login', :with => user.email
      fill_in 'agent_password', :with => user.password
      click_link_or_button('Sign in')
    end

    def wait_until
      require "timeout"
      Timeout.timeout(Capybara.default_wait_time) do
        sleep(0.1) until value = yield
        value
      end
    end

    def do_data_table_search(selector, value)
      within(selector) do
        find(:css,"input[type='text']").set("XXXXXXXXXXXXXXXXXXX")
        sleep(1)
        find(:css,"input[type='text']").set(value)
      end
    end

    def sign_out
      #click_link_or_button('Logout')   
    end

    def confirm_ok_js
      evaluate_script("window.confirm = function(msg) { return true; }")
    end

    def alert_ok_js
      evaluate_script("window.alert = function(msg) { return true; }")
    end

    def select_country_and_state(country = 'US')
      if country == 'US'
        select('United States', :from => 'member[country]')
        within('#states_td'){ select('Alabama', :from => 'member[state]') }
      else
        select('Canada', :from => 'member[country]')
        within('#states_td'){ select('Manitoba', :from => 'member[state]') }
      end
    end

    def search_member(field_selector, value, validate_obj)
      fill_in field_selector, :with => value unless value.nil?
      click_on 'Search'
      sleep 5
      within("#members") do
        assert page.has_content?(validate_obj.status)
        assert page.has_content?("#{validate_obj.visible_id}")
        assert page.has_content?(validate_obj.full_name)
        assert page.has_content?(validate_obj.full_address)

        if !validate_obj.external_id.nil?
          assert page.has_content?(validate_obj.external_id)
        end
      end
    end
        
    def create_member_by_sloop(agent, member, credit_card, enrollment_info, terms_of_membership, validate = true)
      
      credit_card = FactoryGirl.build(:credit_card) if credit_card.nil?
      enrollment_info = FactoryGirl.build(:enrollment_info) if enrollment_info.nil?

      ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns( 
        Hashie::Mash.new( :params => { :transaction_id => '1234', :error_code => '000', 
                                        :auth_code => '111', :duplicate => false, 
                                        :response => 'test', :message => 'done.'}, :message => 'done.', :success => true
            )
      )
      active_merchant_stubs_store(credit_card.number)
      post( api_members_url , { member: {:first_name => member.first_name, 
                                :last_name => member.last_name,
                                :address => member.address,
                                :gender => 'M',
                                :city => member.city, 
                                :zip => member.zip,
                                :state => member.state,
                                :email => member.email,
                                :country => member.country,
                                :type_of_phone_number => member.type_of_phone_number,
                                :phone_country_code => member.phone_country_code,
                                :phone_area_code => member.phone_area_code,
                                :phone_local_number => member.phone_local_number,
                                :enrollment_amount => enrollment_info.enrollment_amount,
                                :terms_of_membership_id => terms_of_membership.id,
                                :birth_date => member.birth_date,
                                :credit_card => {:number => credit_card.number,
                                                 :expire_month => credit_card.expire_month,
                                                 :expire_year => credit_card.expire_year },
                                :product_sku => enrollment_info.product_sku,
                                :product_description => enrollment_info.product_description,
                                :mega_channel => enrollment_info.mega_channel,
                                :marketing_code => enrollment_info.marketing_code,
                                :fulfillment_code => enrollment_info.fulfillment_code,
                                :ip_address => enrollment_info.ip_address
                                },
                                :api_key => agent.authentication_token, :format => :json})
      if validate
        assert_response :success
      end
    end


  def fill_in_member(unsaved_member, credit_card = nil, tom_type = nil, cc_blank = false)
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

    # TODO : FIX THIS.
    # page.execute_script("window.jQuery('#member_birth_date').next().click()")
    # within(".ui-datepicker-calendar") do
    #   click_on("1")
    # end
    
    within("#table_contact_information")do
      fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
      select(type_of_phone_number, :from => 'member[type_of_phone_number]')
      # TODO: select(unsaved_member.type_of_phone_number.capitalize, :from => 'member[type_of_phone_number]') Do we need capitalize ???
      fill_in 'member[email]', :with => unsaved_member.email 
    end

    if not tom_type.nil?
      within("#table_contact_information")do
        select(tom_type, :from => 'member[terms_of_membership_id]') 
      end     
    end 

    fill_in_credit_card_info(credit_card, cc_blank)

    unless unsaved_member.external_id.nil?
      fill_in 'member[external_id]', :with => unsaved_member.external_id
    end 

    alert_ok_js
    click_link_or_button 'Create Member'
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
        fill_in 'member[credit_card][number]', :with => credit_card.number
        select credit_card.expire_month.to_s, :from => 'member[credit_card][expire_month]'
        select credit_card.expire_year.to_s, :from => 'member[credit_card][expire_year]'
      end
    end
  end

  def create_member(unsaved_member, credit_card = nil, tom_type = nil, cc_blank = false)
    fill_in_member(unsaved_member, credit_card, tom_type, cc_blank)
    wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }
    Member.find_by_email(unsaved_member.email)
  end

  # Check Refund email -  It is send it by CS inmediate
  def bill_member(member, do_refund = true, refund_amount = nil, update_next_bill_date_to_today = true)
    active_merchant_stubs
    
    member.update_attribute(:next_retry_bill_date, Time.zone.now)
    next_bill_date = member.bill_date + eval(@terms_of_membership_with_gateway.installment_type)

    answer = member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }
    end
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) }


    within("#table_membership_information")do
      wait_until{ assert page.has_content?(I18n.l member.active_credit_card.last_successful_bill_date, :format => :only_date ) } 
    end

    #sleep(5)

    within("#operations") do
      wait_until {
        assert page.has_selector?("#operations_table")
        assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
      }
    end

    within(".nav-tabs"){ click_on 'Transactions' }
    within("#transactions") do 
      wait_until {
        assert page.has_selector?("#transactions_table")
        Transaction.all.each do |transaction|
          assert page.has_content?(transaction.full_label.truncate(50))
        end
        # assert page.has_content?("Sale : This transaction has been approved")
        assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
      }
    end

    within("#transactions_table") do
     wait_until{ assert page.has_selector?('#refund') }
    end
    
    if do_refund
      transaction = Transaction.last
      visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id, :transaction_id => transaction.id)

      wait_until{ assert page.has_content?(transaction.amount_available_to_refund.to_s) }

      # final_amount = @terms_of_membership_with_gateway.installment_amount.to_s
      final_amount = Transaction.first.amount_available_to_refund
      final_amount = refund_amount.to_s if not refund_amount.nil?


      fill_in 'refund_amount', :with => final_amount   
      assert_difference ['Transaction.count'] do 
        click_on 'Refund'
      end
      
      within("#operations_table") do 
        wait_until {
          assert page.has_content?("Communication 'Test refund' sent")
          assert page.has_content?("Refund success $#{final_amount}")
        }
      end
      within(".nav-tabs"){ click_on 'Transactions' }
      within("#transactions_table") do 
        wait_until {
          assert page.has_content?("Credit : This transaction has been approved")
          assert page.has_content?(final_amount)
        }
      end
      within(".nav-tabs"){ click_on 'Communications' }
      within("#communication") do 
        wait_until {
          assert page.has_content?("Test refund")
          assert page.has_content?("refund")
        }
      end
    end
  end

  def add_credit_card(member,credit_card)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    click_on 'Add a credit card'
    active_merchant_stubs_store(credit_card.number)

    fill_in 'credit_card[number]', :with => credit_card.number
    select credit_card.expire_month.to_s, :from => 'credit_card[expire_month]'
    select credit_card.expire_year.to_s, :from => 'credit_card[expire_year]'

    click_on 'Save credit card'
  end

  def add_club_cash(member, amount, description, validate = true)
    previous_amount = member.club_cash_amount
    new_amount = previous_amount + amount
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.visible_id)
    within("#table_membership_information"){ click_on 'Add club cash' }
    
    alert_ok_js
    fill_in 'club_cash_transaction[amount]', :with => amount
    fill_in 'club_cash_transaction[description]', :with => description
    click_on 'Save club cash transaction'

    if validate
      within('.nav-tabs'){ click_on 'Operations' }
      within("#operations_table"){assert page.has_content?("#{amount.to_f.abs} club cash was successfully #{amount>0 ? 'added' : 'deducted'}. Concept: #{description}")}
      within('.nav-tabs'){ click_on 'Club Cash' }
      within("#td_mi_club_cash_amount") { assert page.has_content?((new_amount).to_s) }
    end
  end

  def save_the_sale(member, new_terms_of_membership, validate = true)
    old_membership = member.current_membership  
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.visible_id)

    click_on 'Save the sale'    
    select(new_terms_of_membership.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on 'Save the sale'
    if validate
      assert page.has_content?("Save the sale succesfully applied")
      member.reload
      old_membership.reload
      assert_equal old_membership.status, "lapsed"
      assert_equal member.current_membership.status, (new_terms_of_membership.needs_enrollment_approval? ? "applied" : "provisional")
      assert_equal member.status, member.current_membership.status
      within("#operations"){assert page.has_content?("Save the sale from TOM(#{old_membership.terms_of_membership.id}) to TOM(#{new_terms_of_membership.id})")}
    end
  end

  def recover_member(member,new_tom, validate = true)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.visible_id)
    wait_until{ assert find_field('input_first_name').value == member.first_name }
    click_link_or_button "Recover"
    select(new_tom.name, :from => 'terms_of_membership_id')
    confirm_ok_js
    click_on "Recover"
    sleep 1
    if validate
      wait_until{ assert find_field('input_first_name').value == member.first_name }
      within("#td_mi_reactivation_times")do
        wait_until{ assert page.has_content?("1")}
      end
    end
  end

  def set_as_undeliverable_member(member, reason = 'Undeliverable', validate = true)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    click_link_or_button "Set undeliverable"
    within("#undeliverable_table"){
      fill_in reason, :with => reason
    }
    confirm_ok_js
    click_link_or_button 'Set wrong address'

    if validate
      member.reload
      within('.nav-tabs'){ click_on 'Operations' }
      within("#operations"){ assert page.has_content?("Address #{member.full_address} is undeliverable. Reason: #{reason}")}
      
      within("#table_demographic_information")do
        assert page.has_css?('tr.yellow')
      end 
      @saved_member.reload
      assert_equal @saved_member.wrong_address, reason
    end
  end

  def search_fulfillments(all_times = false, initial_date = nil, end_date = nil, status = nil, type = nil)
    visit fulfillments_index_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    within("#fulfillments_table")do
      check "all_times" if all_times

      unless initial_date.nil?
        months_difference = initial_date.month - Time.zone.now.month
        within("#td_initial_date")do
          page.execute_script("window.jQuery('#end_date').next().click()")
          within(".ui-datepicker-div") do
            if months_difference > 0
              months_difference.times { click("ui-datepicker-next") }
            elsif months_difference < 0
              months_difference.times { click("ui-datepicker-prev") } 
            end
            
            within(".ui-datepicker-calendar"){ click_on(initial_date.day) }
          end
        end
      end

      unless end_date.nil?
        months_difference = end_date.month - Time.zone.month
        within("#td_end_date")do
          page.execute_script("window.jQuery('#end_date').next().click()")
          if months_difference > 0
            within(".ui-datepicker-div"){ months_difference.times { click("ui-datepicker-next") } }
          elsif months_difference < 0
            within(".ui-datepicker-div"){ months_difference.times { click("ui-datepicker-prev") } }
          end
          within(".ui-datepicker-div") do
            within(".ui-datepicker-calendar"){ click_on(end_date.day) }
          end
        end
      end

      select status, :from => "status" unless status.nil?
      unless type.nil?
        if type == 'sloops'
          find(:css, "#radio_product_type_SLOOPS[value='SLOOPS']").set(true)
        else
          fill_in "product_type", :with => type
        end
      end
    end

    click_link_or_button "Report"
  end

  def update_status_on_fulfillments(fulfillments, new_status, all = false, type = 'KIT-CARD', validate = true)
    within("#report_results")do
      select new_status, :from => "new_status"
      if ['returned','bad_address'].include? new_status 
        fill_in 'reason', :with => "Reason to change."
      end

      if all
        check "fulfillment_select_all"
      else 
        fulfillments.each do |fulfillment|
          check "fulfillment_selected[#{fulfillment.id}]"
        end
      end

      click_link_or_button 'Update status'
      
      if validate
        fulfillments.each do |fulfillment|
          wait_until{assert page.has_content?("Changed status on Fulfillment ##{fulfillment.id} #{type} from #{fulfillment.status} to #{new_status}")}
        end
      end
    end
  end

  def validate_view_member_base(member, status='provisional')
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.visible_id)
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

      within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(member.next_retry_bill_date, :format => :only_date)) } unless ['applied', 'lapsed'].include? member.status 

      assert page.has_selector?("#link_member_change_next_bill_date") unless ['applied', 'lapsed'].include? member.status 

      within("#td_mi_club_cash_amount") { assert page.has_content?("#{member.club_cash_amount.to_f}") }

      assert page.has_selector?("#link_member_add_club_cash") if member.status == 'provisional' or member.status == 'active'

      within("#td_mi_quota") { assert page.has_content?("#{member.quota}") }      
    end  
    if not member.current_membership.enrollment_info.nil?
      if not member.current_membership.enrollment_info.product_sku.blank? and not member.status == 'applied'
        within(".nav-tabs"){ click_on 'Fulfillments' }
        within("#fulfillments") do
          assert page.has_content?('KIT-CARD')
        end
      end
    end
    membership = member.current_membership

    within(".nav-tabs"){ click_on 'Memberships' }
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?(membership.quota.to_s)
      assert page.has_content?(status)
    end
  end

    teardown do
      DatabaseCleaner.clean
      Capybara.reset_sessions!  
      Capybara.use_default_driver
    end
  end
end

module Airbrake
  def self.notify(exception, opts = {})
    # do nothing.
  end
end


 # use_transactional_fixtures = false    # DOES NOT WORK!
   # … think this should be renamed and should definitely get some documentation love.
    
 