require 'test_helper'

class UsersCancelTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_user(create_new_user = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :initial_club_cash_amount => 0)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
 
    @hd_decline = FactoryGirl.create(:hard_decline_strategy_for_billing)
    @sd_decline = FactoryGirl.create(:soft_decline_strategy)
    if create_new_user
      unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
      credit_card = FactoryGirl.build(:credit_card_master_card)
      enrollment_info = FactoryGirl.build(:enrollment_info)
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
      @saved_user = User.find_by_email unsaved_user.email
    end

    sign_in_as(@admin_agent)
  end

  ###########################################################
  # TESTS
  ###########################################################

  test "Downgrade an user when credit card is blank - Same club" do
    setup_user(false)
    credit_card = FactoryGirl.build(:blank_credit_card)
    @unsaved_user = FactoryGirl.build(:active_user, :club_id => @club.id)
    @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership_with_gateway.update_attributes(:if_cannot_bill => "downgrade_tom", :downgrade_tom_id => @terms_of_membership_with_gateway_to_downgrade.id)
    @saved_user = create_user(@unsaved_user, credit_card, @terms_of_membership_with_gateway.name, true)
    
    active_merchant_stubs_process(@hd_decline.response_code, @hd_decline.notes)
    
    @saved_user.update_attribute(:next_retry_bill_date, Time.zone.now)
    prior_status = @saved_user.status

    answer = @saved_user.bill_membership
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within('.nav-tabs'){ click_on "Operations" }
    within("#operations_table")do
      assert page.has_content?("Downgraded member from TOM(#{@terms_of_membership_with_gateway.id}) to TOM(#{@terms_of_membership_with_gateway_to_downgrade.id})")
      assert page.has_content?("Hard Declined: 9997 mes: Credit card is blank we wont bill")
    end
    within('.nav-tabs'){ click_on "Transaction" }
    within('#transactions_table'){ assert page.has_content? "Sale : Credit card is blank we wont bill" }
    
    assert_equal @saved_user.status, prior_status
  end

  test "See Additional User Data" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
  end

  ##TO FIX
  ## test "Downgrade a member - Different club" do
  ##   setup_member(false)
  ##   credit_card = FactoryGirl.build(:credit_card_master_card)
  ##   @club_2 = FactoryGirl.create(:simple_club_with_gateway)
  ##   @unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
  ##   @saved_member = create_member(@unsaved_member, credit_card, @terms_of_membership_with_gateway.name, false)
  ##   @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club_2.id)
  ##   @terms_of_membership_with_gateway.update_attribute(:downgrade_tom_id, @terms_of_membership_with_gateway_to_downgrade.id)  
  ##   active_merchant_stubs_process(@hd_decline.response_code, @hd_decline.notes)
  ##   @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

  ##   answer = @saved_member.bill_membership
  ##   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
  ##   within("#operations_table") do
  ##     assert page.has_content?("Hard Declined: 9997 mes: Credit card is blank we wont bill")
  ##   end
  ## end

  test "Downgrade an user when soft recycled is limit - Same club" do
    setup_user false
    @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership_with_gateway.update_attributes(:if_cannot_bill => "downgrade_tom", :downgrade_tom_id => @terms_of_membership_with_gateway_to_downgrade.id, :installment_amount => 0.54)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by_email unsaved_user.email
    @saved_user.update_attribute(:recycled_times, 4)
    @saved_user.update_attribute(:next_retry_bill_date, Time.zone.now)

    answer = ActiveMerchant::Billing::Response.new(0, @sd_decline.notes, 
      { "transaction_id"=>"c25ccfecae10384698a44360444dead8", "error_code"=> @sd_decline.response_code, 
       "auth_response_text"=>"No Match", "avs_result"=>"N", "auth_code"=>"T5768H" }, 
      { "code"=>"N", "message"=>"Street address and postal code do not match.", 
        "street_match"=>"N", "postal_match"=>"N" })
    ActiveMerchant::Billing::MerchantESolutionsGateway.any_instance.stubs(:purchase).returns(answer)
    answer = @saved_user.bill_membership
  
    operation = @saved_user.operations.where("operation_type = ?", Settings.operation_types.downgrade_user).first
    assert_equal operation.description, "Downgraded member from TOM(#{@terms_of_membership_with_gateway.id}) to TOM(#{@terms_of_membership_with_gateway_to_downgrade.id})"
    assert_equal @saved_user.current_membership.terms_of_membership_id, @terms_of_membership_with_gateway_to_downgrade.id
  end

  test "changing the cancel date" do
    setup_user
    cancel_date = Time.zone.now + 1.day
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_link_or_button 'cancel'
    cancel_date = select_from_datepicker("cancel_date", cancel_date)
    select(@member_cancel_reason.name, :from => 'reason')

    confirm_ok_js
    click_link_or_button 'Cancel user'
    @saved_user.reload
    assert_equal I18n.l(@saved_user.cancel_date, :format => :only_date), I18n.l(cancel_date, :format => :only_date)
    cancel_date = Time.zone.now + 2.day

    click_link_or_button 'cancel'
    cancel_date = select_from_datepicker("cancel_date", cancel_date)
    select(@member_cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_link_or_button 'Cancel user'
    @saved_user.reload
    assert_equal @saved_user.cancel_date.to_date, cancel_date.to_date
  end

  #Check cancel email - It is send it by CS inmediate after user is lapsed
  test "cancel user" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_on 'Cancel'
    date_time = Time.zone.now + 1.day

    date_time = select_from_datepicker("cancel_date", date_time)
    select(@member_cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_on 'Cancel user'

    @saved_user.reload

    within("#td_mi_cancel_date") do
      assert page.has_content?(I18n.l(@saved_user.cancel_date, :format => :only_date))
    end

    @saved_user.reload
    operation = @saved_user.operations.where("operation_type = ?", Settings.operation_types.future_cancel).first
    assert_equal operation.description, "Member cancellation scheduled to #{date_time.to_date} - Reason: #{@member_cancel_reason.name}"
    @saved_user.set_as_canceled!
    
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    
    within("#table_membership_information"){ assert page.has_content?("lapsed") }
    within('.nav-tabs'){ click_on "Communications"}
    within("#communications") do
      assert page.has_content?("Test cancellation")
      assert page.has_content?("cancellation")
    end
    assert_equal(Communication.last.template_type, 'cancellation')
   
    click_link_or_button 'Cancel'
    assert assert find_field('input_first_name').value == @saved_user.first_name
  end

  test "Rejecting an user should set cancel_date" do
    setup_user(false)
    unsaved_user =  FactoryGirl.build(:active_user, :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    @saved_user = create_user(unsaved_user, credit_card, @terms_of_membership_with_approval.name)
    confirm_ok_js
    click_link_or_button 'Reject'

    within("#td_mi_cancel_date")do
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
    end
  end
end