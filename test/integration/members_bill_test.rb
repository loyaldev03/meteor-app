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
        :club_id => @club.id, 
        :terms_of_membership => @terms_of_membership_with_gateway,
        :created_by => @admin_agent)

    create_new_member(unsaved_member)
    
    @saved_member = Member.last
  end

  ############################################################
  # UTILS
  ############################################################

  def validate_cohort(member, enrollment_info, transaction)
    assert_equal transaction.cohort , Member.cohort_formula(member.join_date, enrollment_info, member.club.time_zone, member.terms_of_membership.installment_type), "validate_cohort error"
  end

  def create_new_member(unsaved_member)
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

    answer = member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => member.visible_id)
    
    next_bill_date = member.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    
    validate_cohort(member, EnrollmentInfo.last, Transaction.last)
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

    # Unable to find the refund link
    #within("#transactions_table") do
    #  find("a.btn-warning").click
    #end
    
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
    @saved_member.recover(@terms_of_membership_with_gateway.id)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    next_bill_date = @saved_member.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(next_bill_date, :format => :only_date)) }
    end
  end
  
  test "Change member from Lapse status to active status" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway.id)
    @saved_member.set_as_active
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    
    next_bill_date = @saved_member.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    
    within("#td_mi_next_retry_bill_date")do
      wait_until{ assert page.has_no_content?(I18n.l(next_bill_date, :format => :only_date)) }
    end
  end  

  test "Change Next Bill Date for tomorrow" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway.id)
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
    puts next_bill_date
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
      wait_until{ assert page.has_no_content?(I18n.l(@saved_member.join_date+1.month, :format => :only_date)) }
    end
  end  

  test "Successful payment." do
    setup_member
    @saved_member.join_date = Time.zone.now-3
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }

  end  
end