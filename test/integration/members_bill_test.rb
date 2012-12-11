require 'test_helper'
 
class MembersBillTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(provisional_days = nil)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway.provisional_days = provisional_days unless provisional_days.nil?
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    sign_in_as(@admin_agent)

    unsaved_member = FactoryGirl.build(:member_with_cc, 
        :club_id => @club.id)

    create_new_member(unsaved_member)
    
    @saved_member = Member.last
  end

  ############################################################
  # UTILS
  ############################################################

  def create_new_member(unsaved_member)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_on 'New Member'

    within("#table_demographic_information") {
      fill_in 'member[first_name]', :with => unsaved_member.first_name
      fill_in 'member[last_name]', :with => unsaved_member.last_name
      fill_in 'member[city]', :with => unsaved_member.city
      fill_in 'member[address]', :with => unsaved_member.address
      fill_in 'member[zip]', :with => unsaved_member.zip
      select_country_and_state(unsaved_member.country)
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

    within("#table_credit_card") {  
      fill_in 'member[credit_card][number]', :with => "#{unsaved_member.active_credit_card.number}"
      fill_in 'member[credit_card][expire_month]', :with => "#{unsaved_member.active_credit_card.expire_month}"
      fill_in 'member[credit_card][expire_year]', :with => "#{unsaved_member.active_credit_card.expire_year}"
    }
    
    alert_ok_js

    click_link_or_button 'Create Member'
    sleep(5) #Wait for API response
  end

  def bill_member(member, do_refund = true, refund_amount = nil)
    next_bill_date = member.bill_date + eval(@terms_of_membership_with_gateway.installment_type)

    answer = member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }
    end
    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) }

    #sleep(5)

    within("#operations") do
      wait_until {
        assert page.has_selector?("#operations_table")
        assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
      }
    end

    within("#transactions") do 
      wait_until {
        assert page.has_selector?("#transactions_table")
        assert page.has_content?("Sale : This transaction has been approved")
        assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
      }
    end

    within("#transactions_table") do
     wait_until{ assert page.has_selector?('#refund') }
    end
    
    if do_refund
      visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id, :transaction_id => Transaction.last.id)

      final_amount = @terms_of_membership_with_gateway.installment_amount.to_s
      final_amount = refund_amount.to_s if not refund_amount.nil?

      fill_in 'refund_amount', :with => final_amount   

      assert_difference ['Transaction.count'] do 
        click_on 'Refund'
      end
      
      within("#operations_table") do 
        wait_until {
          assert page.has_content?("Communication 'Test refund' sent")
          assert page.has_content?("Credit success $#{final_amount}")
        }
      end
    
      within("#transactions_table") do 
        wait_until {
          assert page.has_content?("Credit : This transaction has been approved")
          assert page.has_content?(final_amount)
        }
      end
    end

  end

  ############################################################
  # TEST
  ############################################################

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
    setup_member(0)
    EnrollmentInfo.last.update_attribute(:enrollment_amount, 0.0)
    bill_member(@saved_member, false)
  end 

  test "create a member + bill + check fultillment" do
    active_merchant_stubs
    setup_member
    @product = FactoryGirl.create(:product, :club_id => @club.id, :sku => 'kit-card')
    EnrollmentInfo.last.update_attribute(:product_sku, "kit-card")
    @saved_member.send_fulfillment

    bill_member(@saved_member, false)
    
    within("#fulfillments") do 
      wait_until {
        assert page.has_content?("not_processed")
        assert page.has_content?("kit-card")
      }
    end
    
  end

  test "member refund full save" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
     
    assert page.has_content?("Full save done")
    
    within("#operations_table") do 
      wait_until {
        assert page.has_content?("Full save done")
      }
    end
  
  end
 
 
  test "uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => "99999999"   
      
    click_on 'Refund'
    assert page.has_content?("Cant credit more $ than the original transaction amount")
  end
 

  test "two uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, true, (@terms_of_membership_with_gateway.installment_amount / 2))
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
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
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => final_amount.to_s
    assert_difference('Transaction.count') do 
      click_on 'Refund'
    end
    
    within("#operations_table") do 
      wait_until {
        assert page.has_content?("Communication 'Test refund' sent")
        assert page.has_content?("Credit success $#{final_amount}")
      }
    end
  end 

  test "uncontrolled refund special characters" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
    fill_in 'refund_amount', :with => "&%$"
    alert_ok_js
    assert_difference('Transaction.count', 0) do 
      click_on 'Refund'
    end
    
  end

  test "Change member from Provisional (trial) status to Lapse (inactive) status" do
    setup_member
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
   
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
  end

  test "Change member from active status to lapse status" do
    setup_member
    @saved_member.set_as_active!
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
   
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
  end

  test "Change member from Lapse status to Provisional statuss" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    next_bill_date = @saved_member.current_membership.join_date + @terms_of_membership_with_gateway.provisional_days
    
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(next_bill_date, :format => :only_date)) }
    end
  end
  
  test "Change Next Bill Date for blank" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    @saved_member.set_as_active
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    click_link_or_button 'Change'
    wait_until { page.has_content?(I18n.t('activerecord.attributes.member.next_retry_bill_date')) }

    click_link_or_button 'Change next bill date'
    wait_until{ assert page.has_content?(Settings.error_messages.next_bill_date_blank) }
  end  


  test "Change Next Bill Date for tomorrow" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    @saved_member.set_as_active
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    click_link_or_button 'Change'
    wait_until { page.has_content?(I18n.t('activerecord.attributes.member.next_retry_bill_date')) }
    page.execute_script("window.jQuery('#next_bill_date').next().click()")
    within("#ui-datepicker-div") do
      wait_until { click_on("#{Time.zone.now.day+1}") }
    end
    click_link_or_button 'Change next bill date'
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    next_bill_date = Time.zone.now + 1
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(next_bill_date, :format => :only_date)) }
    end
  end  

  test "Next Bill Date for monthly memberships" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    next_bill_date = @saved_member.join_date + eval(@terms_of_membership_with_gateway.installment_type)

    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(@saved_member.current_membership.join_date+1.month, :format => :only_date)) }
    end
  end  

  test "Successful payment." do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
  end  

  test "Provisional member" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    within("#td_mi_status")do
      wait_until{ assert page.has_content?("provisional") }
    end

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      wait_until{ assert page.has_content?("Member enrolled successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-") }
    end
  end 

  test "Lapsed member" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.current_membership.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    answer = @saved_member.bill_membership
    assert (answer[:code] == Settings.error_codes.member_status_dont_allow), answer[:message]
  end 

  test "Refund from CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Transactions")
    end
    within("#transactions_table_wrapper")do
      wait_until{
        assert page.has_selector?('#refund')
        click_link_or_button("Refund")
      }
    end
    wait_until{ fill_in 'refund_amount', :with => final_amount }
    click_link_or_button 'Refund'

    wait_until{ page.has_content?("This transaction has been approved") }

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      wait_until{ assert page.has_content?("Credit success $#{final_amount.to_f}") }
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :dashed)) }
    end
  end 

test "Partial refund from CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Transactions")
    end
    within("#transactions_table_wrapper")do
      wait_until{
        assert page.has_selector?('#refund')
        click_link_or_button("Refund")
      }
    end
    wait_until{ fill_in 'refund_amount', :with => final_amount }
    click_link_or_button 'Refund'

    wait_until{ page.has_content?("This transaction has been approved") }

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      wait_until{ assert page.has_content?("Credit success $#{final_amount.to_f}") }
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :dashed)) }
    end
  end 

  #Refund a transaction with error
  test "Refund a transaction with error" do
    setup_member
    @terms_of_membership_with_gateway.update_attribute(:installment_amount, 45.56)
    @saved_member.active_credit_card.update_attribute(:number,'0000000000000000')


    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    within(".nav-tabs") do
      click_on("Transactions")
    end
    within("#transactions_table_wrapper")do
      wait_until{
        assert page.has_no_selector?('#refund')
      }
    end
  end

  test "Billing membership amount on the Next Bill Date" do
    active_merchant_stubs
    setup_member
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

    next_bill_date = @saved_member.current_membership.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    next_bill_date_after_billing = @saved_member.bill_date + eval(@terms_of_membership_with_gateway.installment_type)


    Member.bill_all_members_up_today

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }
    end

    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date_after_billing, :format => :only_date)) }

    within("#operations") do
      wait_until {
        assert page.has_selector?("#operations_table")
        assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
      }
    end

    within("#transactions") do 
      wait_until {
        assert page.has_selector?("#transactions_table")
        assert page.has_content?("Sale : This transaction has been approved")
        assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
      }
    end

    within("#transactions_table") do
     wait_until{ assert page.has_selector?('#refund') }
    end
  end 

  #See operations on CS
  test "See operations on CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    within(".nav-tabs") do
      click_on("Transactions")
    end
    within("#transactions_table_wrapper")do
      wait_until{
        assert page.has_selector?('#refund')
        click_link_or_button("Refund")
      }
    end
    wait_until{ fill_in 'refund_amount', :with => final_amount }
    click_link_or_button 'Refund'

    wait_until{ page.has_content?("This transaction has been approved") }

    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id, :transaction_id => Transaction.last.id)
    click_on 'Full save'
    assert page.has_content?("Full save done")
    
    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      wait_until{ assert page.has_content?("Member enrolled successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-") }
      wait_until{ assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") }
      wait_until{ assert page.has_content?("Credit success $#{final_amount.to_f}") }
      wait_until{ assert page.has_content?("Full save done") }
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :dashed)) }
    end
  end 

  #Send Prebill email (7 days before NBD)
  test "Send Prebill email (7 days before NBD)" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }    
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now+7.day)
    @saved_member.update_attribute(:bill_date, Time.zone.now+7.day)
    
    sleep 1   
    Member.find_in_batches(:conditions => [" date(bill_date) = ? ", (Time.zone.now + 7.days).to_date ]) do |group|
      group.each do |member| 
        @saved_member.send_pre_bill
      end
    end
    sleep 1
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

    within("#communication") do
      wait_until {
        assert page.has_content?("Test prebill")
        assert page.has_content?("prebill")
        assert_equal(Communication.last.template_type, 'prebill')
      }
    end
   
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Communication 'Test prebill' sent")
      }
    end
  end

end




