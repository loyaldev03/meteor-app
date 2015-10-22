require 'test_helper'

class UsersRecoveryTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_user(cancel = true, create_user = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @new_terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => "another_tom")
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)    

    if create_user
      unsaved_user = FactoryGirl.build(:user_with_api)
      create_user_by_sloop(@admin_agent, unsaved_user, nil, nil, @terms_of_membership_with_gateway)
      
      @saved_user = User.find_by_email(unsaved_user.email)

      if cancel
        cancel_date = Time.zone.now + 1.days
        message = "Member cancellation scheduled to #{cancel_date} - Reason: #{@member_cancel_reason.name}"
        @saved_user.cancel! cancel_date, message, @admin_agent
        @saved_user.set_as_canceled!
  	  end
    end
    sign_in_as(@admin_agent)
  end

  def recover_user(user, tom, product = nil)
    visit show_user_path(:partner_prefix => user.club.partner.prefix, :club_prefix => user.club.name, :user_prefix => user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_on 'Recover'

    if tom.name != @terms_of_membership_with_gateway.name
      select(tom.name, :from => 'terms_of_membership_id')
    end
    if product
      select(product.name, :from => 'product_sku')
    end
    confirm_ok_js
    click_on 'Recover'
    @saved_user.reload
  end

  def cancel_user(user,date_time)
    visit show_user_path(:partner_prefix => user.club.partner.prefix, :club_prefix => user.club.name, :user_prefix => user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_on 'Cancel'
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{date_time.day}")
    end
    select(@member_cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_on 'Cancel user'
    user.set_as_canceled!
  end

  def validate_user_recovery(user, tom)
    visit show_user_path(:partner_prefix => user.club.partner.prefix, :club_prefix => user.club.name, :user_prefix => user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within("#td_mi_status") do
      assert page.has_content?('provisional') if user.status == 'provisional'
      assert page.has_content?('applied') if user.status == 'applied'
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

    membership = user.current_membership
    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      assert page.has_content?(membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
      assert page.has_content?('lapsed')
    end    
    if user.status == 'provisional'
      within("#memberships_table"){ assert page.has_content?('provisional') if user.status == 'provisional' }
    elsif user.status == 'applied'
      within("#memberships_table"){ assert page.has_content?('applied') if user.status == 'applied' }
    end
  end

  ###########################################################
  # TESTS
  ###########################################################

  test "Recover an user using CS which was enrolled with a product sku that does not have stock" do
    setup_user(true, true)
    prods = Product.find_all_by_sku @saved_user.enrollment_infos.first.product_sku.split(',')
    prods.each do |p| 
      p.stock =  0
      p.allow_backorder = false
      p.save
    end
    recover_user(@saved_user,@terms_of_membership_with_gateway)
  end

  test "Recover an user using CS with a new product" do
    setup_user(true, true)
    product = FactoryGirl.create(:product, club_id: @club.id)
    prods = Product.find_all_by_sku @saved_user.enrollment_infos.first.product_sku.split(',')
    prods.each do |p| 
      p.stock =  0
      p.allow_backorder = false
      p.save
    end
    recover_user(@saved_user,@terms_of_membership_with_gateway, product)
    @saved_user.reload
    assert_not_nil @saved_user.fulfillments.where(product_sku: product.sku)
  end

  test "recovery an user with provisional TOM" do
    setup_user
    recover_user(@saved_user,@new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_user.current_membership.terms_of_membership.name}-"

    validate_user_recovery(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test "recovery an user 3 times" do
    setup_user
    3.times do
      if @saved_user.current_membership.terms_of_membership.name == "another_tom"
        tom = @terms_of_membership_with_gateway
      else
        tom = @new_terms_of_membership_with_gateway
      end
      recover_user(@saved_user, tom)
      wait_until{ assert find_field('input_first_name').value == @saved_user.first_name }
      if page.has_no_content?("Cant recover user. Max reactivations reached")
        cancel_user(@saved_user,Time.zone.now + 1.day)        
      end
    end
    assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
    within("#td_mi_reactivation_times") do
      assert page.has_content?("3")
    end
  end

  test "Recover an user by Monthly membership" do
    setup_user
    @new_terms_of_membership_with_gateway.installment_type = "1.month"
    @new_terms_of_membership_with_gateway.save

    recover_user(@saved_user,@new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_user.current_membership.terms_of_membership.name}-"
   
    validate_user_recovery(@saved_user,@new_terms_of_membership_with_gateway)
  end 

  test "Recover an user by Annual Usership" do
    setup_user
    @terms_of_membership_with_gateway.update_attribute(:installment_type, "1.year")
    recover_user(@saved_user, @terms_of_membership_with_gateway)

    assert find_field('input_first_name').value == @saved_user.first_name 
    page.has_content? "Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-"
    validate_user_recovery(@saved_user, @terms_of_membership_with_gateway)
  end

  test "Recovery an user with Paid TOM" do
    setup_user
    actual_tom = @saved_user.current_membership

    recover_user(@saved_user,@terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name
    assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@saved_user.current_membership.terms_of_membership.name}-")

    assert_equal(@saved_user.current_membership.terms_of_membership_id, actual_tom.terms_of_membership_id)
    validate_user_recovery(@saved_user, @terms_of_membership_with_gateway)
  end

  test "When user is blacklisted, it should not let recover" do
    setup_user
    @saved_user.update_attribute(:blacklisted,true)

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
  end

  test "Recover an user with CC blacklisted" do
    setup_user
    @saved_user.active_credit_card.update_attribute(:blacklisted, true )
    assert_equal @saved_user.active_credit_card.blacklisted, true

    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, @saved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    @saved_user.reload

    assert_equal @response.body, '{"message":"There was an error with your credit card information. Please call member services at: 123 456 7891.","code":"9508","errors":{"number":"Credit card is blacklisted"}}'
    assert_equal @saved_user.status, "lapsed"

    validate_view_user_base(@saved_user, "lapsed")
  end

  # Same CC when recovering user (Drupal)
  test "Same CC when recovering user (Sloop)" do
    setup_user
   
    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    assert_difference("CreditCard.count",0) do
      create_user_by_sloop(@admin_agent, @saved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    end
    @saved_user.reload

    assert_equal @saved_user.status, "provisional"
    assert_equal @saved_user.active_credit_card.token, credit_card.token

    validate_view_user_base(@saved_user)
  end

  test "Drupal should not create a new account when updating a lapsed user info in phoenix" do
    setup_user
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)    
    click_link_or_button 'Edit'

    within("#table_demographic_information")do
      fill_in 'user[first_name]', :with => "New name"
    end
    alert_ok_js
    click_link_or_button 'Update User'

    page.has_content? "table_additional_data"

    @saved_user.reload
    assert_equal @saved_user.first_name, "New name"
    assert_equal @saved_user.status, "lapsed"

    credit_card = FactoryGirl.build(:credit_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    assert_difference("CreditCard.count",0) do
      create_user_by_sloop(@admin_agent, @saved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway, false)
    end
    @saved_user.reload

    assert_equal @saved_user.status, "provisional"
    assert_equal @saved_user.active_credit_card.token, credit_card.token

    validate_view_user_base(@saved_user)
  end

  test "Recover an user with CC expired year after (actualYear-3 years)" do
    setup_user
    three_years_before = (Time.zone.now-3.year).year
    @saved_user.active_credit_card.update_attribute(:expire_year, three_years_before )
    @saved_user.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    recover_user(@saved_user, @new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name 
    @saved_user.bill_membership

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name 

    @saved_user.bill_membership

    next_bill_date = Time.zone.now + @new_terms_of_membership_with_gateway.installment_period.days
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{@new_terms_of_membership_with_gateway.id}) -#{@new_terms_of_membership_with_gateway.name}-")
      assert page.has_content?("Member billed successfully $#{@new_terms_of_membership_with_gateway.installment_amount}")
      assert page.has_content?("Renewal scheduled. NBD set #{I18n.l(next_bill_date, :format => :only_date)}")
    end
  end

  test "Recover an user with CC expired year less than (actualYear-3 years)" do
    setup_user
    three_years_before = (Time.zone.now-4.year).year
    @saved_user.active_credit_card.update_attribute(:expire_year, three_years_before )
    @saved_user.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    recover_user(@saved_user, @new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name 
    @saved_user.reload
    @saved_user.bill_membership

    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name 

    next_bill_date = Time.zone.now + eval(@new_terms_of_membership_with_gateway.installment_type)
    within('.nav-tabs'){ click_on 'Operations' }
    within("#operations_table") do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{@new_terms_of_membership_with_gateway.id}) -#{@new_terms_of_membership_with_gateway.name}-")
    end
  end

  # Complimentary users should be active (Recover)
  test "Complimentary users should be active (Enroll)" do
    setup_user false, false
    @terms_of_membership_with_gateway.provisional_days = 0
    @terms_of_membership_with_gateway.installment_amount = 0.0
    @terms_of_membership_with_gateway.save
    enrollment_info = FactoryGirl.build :complete_enrollment_info_with_cero_amount, :product_sku => 'KIT-CARD'
    unsaved_user = FactoryGirl.build(:user_with_api)
    
    assert_difference('User.count') do
      create_user_by_sloop(@admin_agent, unsaved_user, nil, enrollment_info, @terms_of_membership_with_gateway, true, true)
      @saved_user = User.last
    end
    assert_difference('Transaction.count')do
      @saved_user.bill_membership
    end
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('#table_membership_information')do
      within('#td_mi_status'){ assert page.has_content?("active") }
    end  
    assert_equal @saved_user.status, 'active'

    @saved_user.set_as_canceled
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('#table_membership_information')do
      within('#td_mi_status'){ assert page.has_content?("lapsed") }
    end  
    assert_equal @saved_user.status, 'lapsed'

    recover_user( @saved_user, @terms_of_membership_with_gateway )
    validate_user_recovery( @saved_user, @terms_of_membership_with_gateway )
  end
end