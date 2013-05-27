require 'test_helper'

class MembersCancelTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member(create_new_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)
    @hd_decline = FactoryGirl.create(:hard_decline_strategy_for_billing)
    @sd_decline = FactoryGirl.create(:soft_decline_strategy)
    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
  end

  ###########################################################
  # TESTS
  ###########################################################
TO FIX
  test "Downgrade a member when credit card is blank - Same club" do
    setup_member(false)
    credit_card = FactoryGirl.build(:blank_credit_card)
    @unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    @saved_member = create_member(@unsaved_member, credit_card, @terms_of_membership_with_gateway.name, true)
    @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership_with_gateway.update_attribute(:downgrade_tom_id, @terms_of_membership_with_gateway_to_downgrade.id)
    
    active_merchant_stubs_process(@hd_decline.response_code, @hd_decline.notes)
    
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)
    answer = @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#operations_table")do
        assert page.has_content?("Downgraded member from TOM(#{@terms_of_membership_with_gateway.id}) to TOM(#{@terms_of_membership_with_gateway_to_downgrade.id})")
    end
  end

  # test "See Additional Member Data" do
  #   @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
  #   @club = FactoryGirl.create(:simple_club_with_gateway)
  #   @partner = @club.partner
  #   Time.zone = @club.time_zone
  #   @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
  #   @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    
  # end

TO FIX
  test "Downgrade a member - Different club" do
    setup_member(false)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    @club_2 = FactoryGirl.create(:simple_club_with_gateway)
    @unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    @saved_member = create_member(@unsaved_member, credit_card, @terms_of_membership_with_gateway.name, false)
    @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club_2.id)
    @terms_of_membership_with_gateway.update_attribute(:downgrade_tom_id, @terms_of_membership_with_gateway_to_downgrade.id)
    
    active_merchant_stubs_process(@hd_decline.response_code, @hd_decline.notes)
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

    answer = @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#operations_table") do
        assert page.has_content?("Hard Declined: 9997 mes: Credit card is blank we wont bill")
    end
  end


TO FIX
  test "Downgrade a member when soft recycled is limit - Same club" do
    setup_member(false)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    @unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    @saved_member = create_member(@unsaved_member, credit_card, @terms_of_membership_with_gateway.name, false)
    @terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership_with_gateway.update_attribute(:downgrade_tom_id, @terms_of_membership_with_gateway_to_downgrade.id)
    
    active_merchant_stubs_process(@sd_decline.response_code, @sd_decline.notes)
    @saved_member.update_attribute(:recycled_times, 4)
    @saved_member.update_attribute(:next_retry_bill_date, Time.zone.now)

    answer = @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#operations_table")do
        assert page.has_content?("Downgraded member from TOM(#{@terms_of_membership_with_gateway.id}) to TOM(#{@terms_of_membership_with_gateway_to_downgrade.id})")
    end
  end



  #Check cancel email - It is send it by CS inmediate after member is lapsed
  test "changing the cancel date" do
     setup_member

     cancel_reason = FactoryGirl.create(:member_cancel_reason, :club_id => 1)
     visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
     click_link_or_button 'cancel'
     sleep 1
     page.execute_script("window.jQuery('#cancel_date').next().click()")
     within("#ui-datepicker-div") do
       if ((Time.zone.now+1.day).month != Time.zone.now.month)
         within(".ui-datepicker-header")do
         find(".ui-icon-circle-triangle-e").click
         end
       end
     end
   first(:link, "#{(Time.zone.now+1.day).day}").click
   select(cancel_reason.name, :from => 'reason')
   confirm_ok_js
   click_link_or_button 'Cancel member'
   sleep 2
   click_link_or_button 'cancel'
   sleep 1
     page.execute_script("window.jQuery('#cancel_date').next().click()")
     within("#ui-datepicker-div") do
       if ((Time.zone.now+2.day).month != Time.zone.now.month)
         within(".ui-datepicker-header")do
         first(:link, "#{(Time.zone.now+1.day).day}").click
         end
       end
     end
   click_on("#{(Time.zone.now+2.day).day}")
   select(cancel_reason.name, :from => 'reason')
   confirm_ok_js
   click_link_or_button 'Cancel member'
   end


  test "cancel member" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Cancel'
    date_time = Time.zone.now + 1.days

    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within("#ui-datepicker-div") do
      wait_until { click_on("#{date_time.day}") }
    end
    select(@member_cancel_reason.name, :from => 'reason')
    confirm_ok_js
    click_on 'Cancel member'

    @saved_member.reload

    within("#td_mi_cancel_date") do
      assert page.has_content?(I18n.l(@saved_member.cancel_date, :format => :only_date))
    end
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member cancellation scheduled to #{date_time.to_date} - Reason: #{@member_cancel_reason.name}")
      }
    end

    @saved_member.reload
    @saved_member.set_as_canceled!
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    
    within("#table_membership_information") do
      assert page.has_content?("lapsed")
    end
      
    within("#communication") do
      wait_until {
        assert page.has_content?("Test cancellation")
        assert page.has_content?("cancellation")
        assert_equal(Communication.last.template_type, 'cancellation')
      }
    end
   
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member canceled")
      }
    end
    click_link_or_button 'Cancel'
    wait_until{ assert assert find_field('input_first_name').value == @saved_member.first_name }
  end

  test "Rejecting a member should set cancel_date" do
    setup_member(false)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    fill_in_member_approval(unsaved_member, credit_card)
    select(@terms_of_membership_with_approval.name, :from => 'member[terms_of_membership_id]')

    wait_until { assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    confirm_ok_js
    click_link_or_button 'Reject'

    within("#td_mi_cancel_date")do
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
  end


end