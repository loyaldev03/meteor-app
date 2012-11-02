require 'test_helper'

class MembersRecoveryTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)
    saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    
    cancel_date = Time.zone.now + 1.days
    message = "Member cancellation scheduled to #{cancel_date} - Reason: #{@member_cancel_reason.name}"
    saved_member.cancel! cancel_date, message, @admin_agent
    saved_member.set_as_canceled!

    @canceled_member = Member.first
	
    sign_in_as(@admin_agent)
  end

  test "recovery a member with provisional TOM" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'
    
    assert page.has_content?("Member recovered successfully $0.0")
    
    within("#td_mi_status") do
      assert page.has_content?("provisional")
    end
    
    within("#td_mi_reactivation_times") do
      assert page.has_content?("1")
    end
    
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member recovered successfully $0.0")
      }
    end
    membership = @canceled_member.current_membership
    within(".nav-tabs") do
      click_on("Memberships")
    end
    within("#memberships_table")do
      wait_until{
        assert page.has_content?(membership.id.to_s)
        assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
        assert page.has_content?(membership.quota.to_s)
        assert page.has_content?('lapsed')
        assert page.has_content?('provisional')
      }
    end    
  end

  test "recovery a member 3 times" do
    setup_member
    3.times{ 
      visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
      click_on 'Recover'
      if page.has_no_content?("Cant recover member. Max reactivations reached")
        sleep(2)
        click_on 'Cancel'
        date_time = Time.zone.now + 1.days
        page.execute_script("window.jQuery('#cancel_date').next().click()")
        within("#ui-datepicker-div") do
          click_on("#{date_time.day}")
        end
        select(@member_cancel_reason.name, :from => 'reason')
        confirm_ok_js
        click_on 'Cancel member'
        Member.last.set_as_canceled!
      end
    }
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    assert page.has_content?(Settings.error_messages.cant_recover_member)
  end

  test "Recover a member by Monthly membership" do
    setup_member
    @terms_of_membership_with_gateway.installment_type = "1.month"

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'
    wait_until{ page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-") }
   
    within("#td_mi_status") do
      assert page.has_content?("provisional")
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
      wait_until{
        assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-")
      }
    end
  end 

  test "Recover a member by Annual Membership" do
    setup_member
    @terms_of_membership_with_gateway.installment_type = "1.year"

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'
    wait_until{ page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-") }
   
    within("#td_mi_status") do
      assert page.has_content?("provisional")
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
      wait_until{
        assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-")
      }
    end
  end 

  test "Recovery a member with Paid TOM" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    actual_tom = @canceled_member.current_membership

    click_on 'Recover'
    wait_until{ assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-") }
    @canceled_member.reload
    wait_until{ assert_equal(@canceled_member.current_membership.terms_of_membership_id, actual_tom.terms_of_membership_id) }

    within("#td_mi_reactivation_times")do
      wait_until{ assert page.has_content?(1.to_s) }
    end
    within("#td_mi_join_date") do
      assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date))
    end
    within(".nav-tabs") do
      click_on("Operations")
    end
    within("#operations_table")do
      wait_until{
        assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@terms_of_membership_with_gateway.name}-")
      }
    end
  end

  test "Recovery time on approval members" do
    setup_member
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    unsaved_member =  FactoryGirl.build(:active_member, 
                                         :club_id => @club.id)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    
    #fill_in_member_approval(unsaved_member,credit_card)

    # wait_until{ assert find_field('input_first_name').value == unsaved_member.first_name }

    # @saved_member = Member.find_by_email(unsaved_member.email)

    # visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    # wait_until{ assert find_field('input_first_name').value == @saved_member.first_name }
    # wait_until{ page.has_selector?('#approve') }
    # wait_until{ page.has_selector?('#reject') }
  end

end