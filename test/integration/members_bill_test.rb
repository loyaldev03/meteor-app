require 'test_helper'
 
class MembersBillTest < ActionController::IntegrationTest


  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_member(provisional_days = nil, create_member = true)
    active_merchant_stubs

    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner

    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway.provisional_days = provisional_days unless provisional_days.nil?
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    
    sign_in_as(@admin_agent)

    if create_member
      unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
      @saved_member = create_member(unsaved_member)
    end
  end

  ############################################################
  # UTILS
  ############################################################
    
  def make_a_refund(transaction, amount, check_refund = true)
    visit member_refund_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id, :transaction_id => transaction.id)
    fill_in 'refund_amount', :with => amount.to_s  
  
    alert_ok_js      
    click_on 'Refund'
    sleep(5) #wait for communication to be sent. 
    if check_refund
      page.has_content?("This transaction has been approved")
      within(".nav-tabs"){ click_on("Operations") }
      within("#operations_table")do
        assert page.has_content?("Communication 'Test refund' sent")
        assert page.has_content?("Refund success $#{amount.to_f}")
      end
    end
  end
  
  def change_next_bill_date(date)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    click_link_or_button 'Change'
    page.has_content?(I18n.t('activerecord.attributes.member.next_retry_bill_date'))
    unless date.nil?
      page.execute_script("window.jQuery('#next_bill_date').next().click()")
      within("#ui-datepicker-div") do
        if (date.month != Time.zone.now.month)
          within(".ui-datepicker-header")do
            find(".ui-icon-circle-triangle-e").click
          end
        end
        sleep 1
        first(:link, date.day.to_s).click
      end
    end
    click_link_or_button 'Change next bill date'
  end

  ############################################################
  # TEST
  ############################################################

  test "Change Next Bill Date" do
    setup_member(nil,true)
    bill_member(@saved_member,false,nil,false)
    next_bill_date = Time.zone.now.to_date + 1.day
    change_next_bill_date(next_bill_date)
    find(".alert", :text => "Next bill date changed to #{next_bill_date.to_date}")
  end

  test "See HD for 'Soft recycle limit'" do
    setup_member
    EnrollmentInfo.last.update_attribute(:enrollment_amount, 0.0)
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    @hd_strategy = FactoryGirl.create(:hard_decline_strategy) 
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)

    within('#table_membership_information') do
      within('#td_mi_recycled_times') do
        assert page.has_content? "0"
      end
      within('#td_mi_status') do
        assert page.has_content?('provisional')
      end
    end
    recycle_time = 0
    2.upto(5) do |time|
      @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)
      answer = @saved_member.bill_membership
      recycle_time = recycle_time+1
      @saved_member.reload
      visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)

      if @saved_member.next_retry_bill_date.nil?
        within('#table_membership_information') do
          within('#td_mi_recycled_times') do
            assert page.has_content? "0"
          end
          within('#td_mi_status') do
            assert page.has_content?('lapsed')
          end
        end
      else
        within('#table_membership_information') do
          within('#td_mi_recycled_times') do
            assert page.has_content?(recycle_time.to_s)
          end
          within('#td_mi_status') do
            assert page.has_content?('provisional')
          end
        end
      end
    end
  end

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

  test "uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    
    assert_difference('Transaction.count', 0) do 
      make_a_refund(Transaction.last, 999999, false)
    end
    assert page.has_content?("Cant credit more $ than the original transaction amount")
  end

  test "two uncontrolled refund more than transaction amount" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, true, (@terms_of_membership_with_gateway.installment_amount / 2))
    amount_to_refund = (@terms_of_membership_with_gateway.installment_amount / 2) + 1
    assert_difference('Transaction.count', 0) do 
      make_a_refund(Transaction.find_by_operation_type(101), amount_to_refund, false)
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
    assert_difference('Transaction.count') do 
      @saved_member.reload
      make_a_refund(@saved_member.transactions.where("operation_type = 101").order("created_at ASC").first, final_amount)
    end
  end 

  test "uncontrolled refund special characters" do
    active_merchant_stubs
    setup_member
    bill_member(@saved_member, false)
    assert_difference('Transaction.count', 0) do 
      make_a_refund(Transaction.last, "&%$", false)
    end
  end

  test "Change member from Provisional (trial) status to Lapse (inactive) status" do
    setup_member
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
   
    within("#td_mi_next_retry_bill_date")do
      assert page.has_no_content?(I18n.l(Time.zone.now.in_time_zone(@saved_member.get_club_timezone), :format => :only_date))
    end
  end

  test "Change member from active status to lapsed status" do
    setup_member
    @saved_member.set_as_active!
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
   
    within("#td_mi_next_retry_bill_date")do
      assert page.has_no_content?(I18n.l(Time.zone.now.in_time_zone(@saved_member.get_club_timezone), :format => :only_date))
    end
  end

  test "Change member from Lapse status to Provisional status" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    next_bill_date = @saved_member.current_membership.join_date + @terms_of_membership_with_gateway.provisional_days
    
    within("#td_mi_next_retry_bill_date")do
      assert page.has_no_content?(I18n.l(next_bill_date, :format => :only_date))
    end
  end
  
  test "Change Next Bill Date for blank" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway)
    @saved_member.set_as_active
    
    change_next_bill_date(nil)
    assert page.has_content?(I18n.t('error_messages.next_bill_date_blank'))
  end  

  test "Change Next Bill Date for tomorrow" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.recover(@terms_of_membership_with_gateway) 
    @saved_member.set_as_active
    next_bill_date = Time.zone.now + 1.day
    change_next_bill_date(next_bill_date)
    assert find_field('input_first_name').value == @saved_member.first_name
    within("#td_mi_next_retry_bill_date")do
      assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)), "Timezone: #{Time.zone}, date: #{next_bill_date}"
    end
  end  

  test "Next Bill Date for monthly memberships" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    first_bill_date = @saved_member.join_date + @terms_of_membership_with_gateway.provisional_days.days

    within("#td_mi_next_retry_bill_date")do
      assert page.has_content?(I18n.l(first_bill_date, :format => :only_date))
    end

    bill_member(@saved_member, false)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    second_bill_date = first_bill_date + @terms_of_membership_with_gateway.installment_period.days

    within("#td_mi_next_retry_bill_date")do
      assert page.has_content?(I18n.l(second_bill_date, :format => :only_date))
    end 
  end  
  
  test "Refund a transaction with error" do
    setup_member
    @terms_of_membership_with_gateway.update_attribute(:installment_amount, 45.56)
    active_merchant_stubs("34234", "decline stubbed", false)
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within(".nav-tabs") do
      click_on("Transactions")
    end
    within("#transactions_table_wrapper")do
      assert page.has_no_selector?('#refund')
    end
  end

  test "Successful payment." do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      assert page.has_content?("Member billed successfully $100.0 Transaction id: #{Transaction.last.id}")
    end
  end  

  test "Provisional member" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    within("#td_mi_status")do
      assert page.has_content?("provisional")
    end

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-")
    end
  end 

  test "Lapsed member" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    answer = @saved_member.bill_membership
    assert (answer[:code] == Settings.error_codes.member_status_dont_allow), answer[:message]
  end 

  test "Refund from CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table_wrapper"){ assert page.has_selector?('#refund') }
    make_a_refund(Transaction.last, final_amount)
  end 
  
  test "Partial refund from CS" do
    setup_member
    @saved_member.current_membership.join_date = Time.zone.now-3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2);
    bill_member(@saved_member, false, final_amount)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within(".nav-tabs"){ click_on("Transactions") }
    within("#transactions_table_wrapper")do
      assert page.has_selector?('#refund')
    end
    make_a_refund(Transaction.last, final_amount)
    page.has_content?("This transaction has been approved")
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?("Refund success $#{final_amount.to_f}")
      assert page.has_content?(I18n.l(Time.zone.now.in_time_zone(@saved_member.get_club_timezone), :format => :only_date))
    end
  end 

  test "Billing membership amount on the Next Bill Date" do
    active_merchant_stubs
    setup_member
    next_bill_date = @saved_member.current_membership.join_date + @terms_of_membership_with_gateway.provisional_days.days
    next_bill_date_after_billing = @saved_member.next_retry_bill_date + @terms_of_membership_with_gateway.installment_period.days

    excecute_like_server(@club.time_zone) do
      bill_member(@saved_member, false)
    end
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information") do
      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }
    end

    within('.nav-tabs'){ click_on 'Transactions'}
    within("#transactions_table") do
      assert page.has_content?("Sale : This transaction has been approved")
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
    end
  end 

  # supervisor should be able to refund
  test "Representative and Supervisor should be able to refund" do
    active_merchant_stubs
    setup_member
    ["representative", "supervisor"].each do |role|
      @admin_agent.update_attribute(:roles, role)
      excecute_like_server(@club.time_zone) do
        bill_member(@saved_member, true)
      end
    end
  end 

  test "Hard decline for user without CC information when the billing date arrives" do
    setup_member(nil,false)
    @hd_strategy = FactoryGirl.create(:hard_decline_strategy_for_billing)
    active_merchant_stubs("9997", "This transaction has not been approved with stub", false)
    
    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
    @saved_member = create_member(unsaved_member, nil, nil, true)

    within("#table_active_credit_card")do
      assert page.has_content?("0000 (unknown)")
    end
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

    assert_difference("Communication.count",2)do
      excecute_like_server(@club.time_zone) do
        excecute_like_server(@club.time_zone) do
          TasksHelpers.bill_all_members_up_today
        end
      end
    end

    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within('.nav-tabs'){ click_on 'Operations'}
    within("#operations"){ assert page.has_content?("Communication 'Test hard_decline' sent") } 
    within("#operations"){ assert page.has_content?("Communication 'Test cancellation' sent") } 
    within("#operations"){ assert page.has_content?("Member canceled") } 
    within(".nav-tabs"){ click_on 'Communications' }
    within("#communications"){ assert page.has_content?("hard_decline") }
    within("#communications"){ assert page.has_content?("cancellation") }
  end

  test "Try billing a member with credit card ok, and within a club that allows billing." do
    setup_member
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)      
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    fill_in('amount', :with => '100')
    fill_in('description', :with => 'asd')
    click_link_or_button (I18n.t('buttons.no_recurrent_billing'))

    trans = Transaction.last
    assert page.has_content? "Member billed successfully $100 Transaction id: #{trans.uuid}. Reason: asd"

    within(".nav-tabs") {click_on 'Operations'}
    within("#operations") {assert page.has_content? "Member billed successfully $100 Transaction id: #{trans.uuid}. Reason: asd"}
    within(".nav-tabs") {click_on 'Transactions'}  
    within("#transactions_table") do
      assert page.has_content?("Sale : This transaction has been approved")
      assert page.has_content?("100")
      assert page.has_selector?('#refund')
    end
  end

  test "Try billing a member without providing the amount and/or description" do
    setup_member
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    assert page.has_content?("Amount, description and type cannot be blank.")
    fill_in('amount', :with => '100')
    click_link_or_button (I18n.t('buttons.no_recurrent_billing'))
    assert page.has_content?("Amount, description and type cannot be blank.")
    fill_in('amount', :with => '')
    fill_in('description', :with => 'asd')
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    assert page.has_content?("Amount, description and type cannot be blank.")
  end

  test "Try billing a member without providing the amount and/or description." do
    setup_member
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    fill_in('amount', :with => '-100')
    fill_in('description', :with => 'asd')
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    assert page.has_content?("Amount must be greater than 0.")
  end

  test "Try billing a member within a club that do not allow billing." do
    setup_member
    @saved_member.club.update_attribute( :billing_enable, false)
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    assert find(:xpath, "//a[@id='no_recurrent_bill_btn' and @disabled='disabled']")
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    assert page.has_selector?('#blacklist_btn')
  end

  test "Try billing a member with blank credit card." do
    setup_member(nil,false)
    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)      
    @saved_member = create_member(unsaved_member,nil,nil, true)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    fill_in('amount', :with => '100')
    fill_in('description', :with => 'asd')
    click_link_or_button(I18n.t('buttons.no_recurrent_billing')) 
    assert page.has_content?("Credit card is blank we wont bill")   
  end

  # stubs isnt working correctly
  test "Litle payment gateway (Enrollment amount)" do
    setup_member(false)
    @club = FactoryGirl.create(:simple_club_with_litle_gateway, :name => "new_club", :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway_for_litle = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :provisional_days => 0)
    
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway_for_litle)
    @saved_member=Member.find_by_email(unsaved_member.email)
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    transaction = Transaction.last
    make_a_refund(transaction, transaction.amount_available_to_refund)
  end

  test "Litle payment gateway (Installment amount)" do
    active_merchant_stubs_litle
    setup_member(false)
    @club = FactoryGirl.create(:simple_club_with_litle_gateway, :name => "new_club", :partner_id => @partner.id)
    @terms_of_membership_with_gateway_for_litle = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info, :enrollment_amount => false)
    create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway_for_litle)
    @saved_member=Member.find_by_email(unsaved_member.email)
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    Time.zone = @club.time_zone
    bill_member(@saved_member, true, nil, true)
  end
end