require 'test_helper'

class MembersRecoveryTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_member(cancel = true, create_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @new_terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => "another_tom")
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)    

    if create_member
      unsaved_member = FactoryGirl.build(:member_with_api)
      create_member_by_sloop(@admin_agent, unsaved_member, nil, nil, @terms_of_membership_with_gateway)
      
      @saved_member = Member.find_by_email(unsaved_member.email)

      if cancel
        cancel_date = Time.zone.now + 1.days
        message = "Member cancellation scheduled to #{cancel_date} - Reason: #{@member_cancel_reason.name}"
        @saved_member.cancel! cancel_date, message, @admin_agent
        @saved_member.set_as_canceled!
  	  end
    end
    sign_in_as(@admin_agent)
  end

  def recover_member(member, tom)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    
    click_on 'Recover'

    if tom.name != @terms_of_membership_with_gateway.name
      select(tom.name, :from => 'terms_of_membership_id')
    end
    confirm_ok_js
    click_on 'Recover'
    @saved_member.reload
  end

  def cancel_member(member,date_time)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    click_on 'Cancel'
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{date_time.day}")
    end
    select(@member_cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_on 'Cancel member'
    member.set_as_canceled!
  end

  def validate_member_recovery(member, tom)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within("#td_mi_status") do
      assert page.has_content?('provisional') if member.status == 'provisional'
      assert page.has_content?('applied') if member.status == 'applied'
    end
    within("#td_mi_join_date") do
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
    end
    within("#td_mi_reactivation_times") do
      assert page.has_content?("1")
    end

    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{tom.id}) -#{tom.name}-")
    end

    membership = member.current_membership
    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('lapsed')
    end    
    if member.status == 'provisional'
      within("#memberships_table"){ assert page.has_content?('provisional') if member.status == 'provisional' }
    elsif member.status == 'applied'
      within("#memberships_table"){ assert page.has_content?('applied') if member.status == 'applied' }
    end
  end

  ###########################################################
  # TESTS
  ###########################################################
  
  test "Recover a member using CS which was enrolled with a product sku that does not have stock" do
    setup_member(true, true)
    prods = Product.find_all_by_sku @saved_member.enrollment_infos.first.product_sku.split(',')
    prods.each do |p| 
      p.stock =  0
      p.allow_backorder = false
      p.save
    end
    recover_member(@saved_member,@terms_of_membership_with_gateway)
  end

  test "recovery a member with provisional TOM" do
    setup_member
    recover_member(@saved_member,@new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_member.first_name
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_member.current_membership.terms_of_membership.name}-"

    validate_member_recovery(@saved_member, @new_terms_of_membership_with_gateway)
  end

  test "recovery a member 3 times" do
    setup_member
    3.times do
      if @saved_member.current_membership.terms_of_membership.name == "another_tom"
        tom = @terms_of_membership_with_gateway
      else
        tom = @new_terms_of_membership_with_gateway
      end
      recover_member(@saved_member, tom)
      wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
      if page.has_no_content?("Cant recover member. Max reactivations reached")
        cancel_member(@saved_member,Time.zone.now + 1.day)        
      end
    end
    assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
    within("#td_mi_reactivation_times") do
      assert page.has_content?("3")
    end
  end

  test "Recover a member by Monthly membership" do
    setup_member
    @new_terms_of_membership_with_gateway.installment_type = "1.month"
    @new_terms_of_membership_with_gateway.save

    recover_member(@saved_member,@new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_member.first_name
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_member.current_membership.terms_of_membership.name}-"
   
    validate_member_recovery(@saved_member,@new_terms_of_membership_with_gateway)
  end 

  test "Recover a member by Annual Membership" do
    setup_member
    @terms_of_membership_with_gateway.update_attribute(:installment_type, "1.year")
    recover_member(@saved_member, @terms_of_membership_with_gateway)

    assert find_field('input_first_name').value == @saved_member.first_name 
    page.has_content? "Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-"
    validate_member_recovery(@saved_member, @terms_of_membership_with_gateway)
  end

  test "Recovery a member with Paid TOM" do
    setup_member
    actual_tom = @saved_member.current_membership

    recover_member(@saved_member,@terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_member.first_name
    assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@saved_member.current_membership.terms_of_membership.name}-")

    assert_equal(@saved_member.current_membership.terms_of_membership_id, actual_tom.terms_of_membership_id)
    validate_member_recovery(@saved_member, @terms_of_membership_with_gateway)
  end

  test "When member is blacklisted, it should not let recover" do
    setup_member
    @saved_member.update_attribute(:blacklisted,true)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
  end

  test "Recover a member with CC blacklisted" do
    setup_member
    @saved_member.active_credit_card.update_attribute(:blacklisted, true )
    assert_equal @saved_member.active_credit_card.blacklisted, true

    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, @saved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    @saved_member.reload

    assert_equal @response.body, '{"message":"There was an error with your credit card information. Please call member services at: 123 456 7891.","code":"9508","errors":{"number":"Credit card is blacklisted"}}'
    assert_equal @saved_member.status, "lapsed"

    validate_view_member_base(@saved_member, "lapsed")
  end

  # Same CC when recovering member (Drupal)
  test "Same CC when recovering member (Sloop)" do
    setup_member
   
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    assert_difference("CreditCard.count",0) do
      create_member_by_sloop(@admin_agent, @saved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    end
    @saved_member.reload

    assert_equal @saved_member.status, "provisional"
    assert_equal @saved_member.active_credit_card.token, credit_card.token

    validate_view_member_base(@saved_member)
  end

  test "Drupal should not create a new account when updating a lapsed member info in phoenix" do
    setup_member
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)    
    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      fill_in 'member[first_name]', :with => "New name"
    end
    alert_ok_js
    click_link_or_button 'Update Member'

    page.has_content? "table_additional_data"

    @saved_member.reload
    assert_equal @saved_member.first_name, "New name"
    assert_equal @saved_member.status, "lapsed"

    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    assert_difference("CreditCard.count",0) do
      create_member_by_sloop(@admin_agent, @saved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    end
    @saved_member.reload

    assert_equal @saved_member.status, "provisional"
    assert_equal @saved_member.active_credit_card.token, credit_card.token

    validate_view_member_base(@saved_member)
  end

  test "Recover a member with CC expired year after (actualYear-3 years)" do
    setup_member
    three_years_before = (Time.zone.now-3.year).year
    @saved_member.active_credit_card.update_attribute(:expire_year, three_years_before )
    @saved_member.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    recover_member(@saved_member, @new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_member.first_name 
    @saved_member.bill_membership

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name 

    @saved_member.bill_membership

    next_bill_date = Time.zone.now + @new_terms_of_membership_with_gateway.installment_period.days
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{@new_terms_of_membership_with_gateway.id}) -#{@new_terms_of_membership_with_gateway.name}-")
      assert page.has_content?("Member billed successfully $#{@new_terms_of_membership_with_gateway.installment_amount}")
      assert page.has_content?("Renewal scheduled. NBD set #{I18n.l(next_bill_date, :format => :only_date)}")
    end
  end

  test "Recover a member with CC expired year less than (actualYear-3 years)" do
    setup_member
    three_years_before = (Time.zone.now-4.year).year
    @saved_member.active_credit_card.update_attribute(:expire_year, three_years_before )
    @saved_member.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    recover_member(@saved_member, @new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_member.first_name 
    @saved_member.reload
    @saved_member.bill_membership

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name 

    next_bill_date = Time.zone.now + eval(@new_terms_of_membership_with_gateway.installment_type)
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{@new_terms_of_membership_with_gateway.id}) -#{@new_terms_of_membership_with_gateway.name}-")
    end
  end

  # Complimentary members should be active (Recover)
  test "Complimentary members should be active (Enroll)" do
    setup_member false, false
    @terms_of_membership_with_gateway.provisional_days = 0
    @terms_of_membership_with_gateway.installment_amount = 0.0
    @terms_of_membership_with_gateway.save
    enrollment_info = FactoryGirl.build :complete_enrollment_info_with_cero_amount, :product_sku => 'KIT-CARD'
    unsaved_member = FactoryGirl.build(:member_with_api)
    
    assert_difference('Member.count') do
      create_member_by_sloop(@admin_agent, unsaved_member, nil, enrollment_info, @terms_of_membership_with_gateway, true, true)
      @saved_member = Member.last
    end
    assert_difference('Transaction.count')do
      @saved_member.bill_membership
    end
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('#table_membership_information')do
      within('#td_mi_status'){ assert page.has_content?("active") }
    end  
    assert_equal @saved_member.status, 'active'

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within('#table_membership_information')do
      within('#td_mi_status'){ assert page.has_content?("lapsed") }
    end  
    assert_equal @saved_member.status, 'lapsed'

    recover_member( @saved_member, @terms_of_membership_with_gateway )
    validate_member_recovery( @saved_member, @terms_of_membership_with_gateway )
  end
end