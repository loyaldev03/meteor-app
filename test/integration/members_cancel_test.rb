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
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)

    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
  end


  test "cancel member" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Cancel'
    date_time = Time.zone.now + 1.days

    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{date_time.day}")
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
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    within("#table_membership_information") do
      assert page.has_content?("lapsed")
    end
      
    within("#communication") do
      wait_until {
        assert page.has_content?("Test cancellation")
      }
    end
   
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member canceled")
        assert page.has_content?("Communication 'Test cancellation' sent")
      }
    end
    click_link_or_button 'Cancel'
    sleep 2
    wait_until{ assert assert find_field('input_first_name').value == @saved_member.first_name }
  end


end