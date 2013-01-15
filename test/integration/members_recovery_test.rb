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
    @new_terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => "another_tom")
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
    
    wait_until{
      select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    }
    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload

    wait_until{ page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-"}

    within("#td_mi_status") do
      assert page.has_content?("provisional")
    end
    
    within("#td_mi_reactivation_times") do
      assert page.has_content?("1")
    end
    
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-")
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
      wait_until{
        if @canceled_member.current_membership.terms_of_membership.name == "another_tom"
          select(@terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
        else
          select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
        end
      }
      confirm_ok_js
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
    wait_until { assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']") }
  end

  test "Recover a member by Monthly membership" do
    setup_member
    @new_terms_of_membership_with_gateway.installment_type = "1.month"
    @new_terms_of_membership_with_gateway.save

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    wait_until{
      select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    }
    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload

    wait_until{ page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-"}
   
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
        assert page.has_content?("Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-")
      }
    end
  end 

  test "Recover a member by Annual Membership" do
    setup_member
    @terms_of_membership_with_gateway.installment_type = "1.year"
    @terms_of_membership_with_gateway.save

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    wait_until{
      select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    }
    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload

    wait_until{ page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-"}

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
        assert page.has_content?("Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-")
      }
    end
  end 

  test "Recovery a member with Paid TOM" do
    setup_member
    actual_tom = @canceled_member.current_membership

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload

    wait_until{ assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@canceled_member.current_membership.terms_of_membership.name}-") }
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
        assert page.has_content?("Member recovered successfully $0.0 on TOM(1) -#{@canceled_member.current_membership.terms_of_membership.name}-")
      }
    end
  end

  test "When member is blacklisted, it should not let recover" do
    setup_member
    @canceled_member.update_attribute(:blacklisted,true)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    
    wait_until { find(:xpath, "//a[@id='recovery' and @disabled='disabled']") }
  end

  test "Recover a member with CC expired year after (actualYear-3 years)" do
    setup_member
    three_years_before = (Time.zone.now-3.year).year
    @canceled_member.active_credit_card.update_attribute(:expire_year, three_years_before )
    @canceled_member.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    wait_until{
      select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    }
    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload
    @canceled_member.bill_membership

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }

    next_bill_date = Time.zone.now + eval(@new_terms_of_membership_with_gateway.installment_type)
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-")
        assert page.has_content?("Member billed successfully $#{@new_terms_of_membership_with_gateway.installment_amount}")
        assert page.has_content?("Renewal scheduled. NBD set #{I18n.l(next_bill_date, :format => :only_date)}")
        assert page.has_content?("#{@new_terms_of_membership_with_gateway.club_cash_amount} club cash was successfully added. Concept: Adding club cash after billing")
      }
    end
  end

  test "Recover a member with CC expired year less than (actualYear-3 years)" do
    setup_member
    three_years_before = (Time.zone.now-4.year).year
    @canceled_member.active_credit_card.update_attribute(:expire_year, three_years_before )
    @canceled_member.active_credit_card.update_attribute(:expire_month, Time.zone.now.month)
    @new_terms_of_membership_with_gateway.update_attribute(:provisional_days, 0)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    click_on 'Recover'

    wait_until{
      select(@new_terms_of_membership_with_gateway.name, :from => 'terms_of_membership_id')
    }
    confirm_ok_js
    click_on 'Recover'

    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }
    @canceled_member.reload
    @canceled_member.bill_membership

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @canceled_member.visible_id)
    wait_until{ assert find_field('input_first_name').value == @canceled_member.first_name }

    next_bill_date = Time.zone.now + eval(@new_terms_of_membership_with_gateway.installment_type)
    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member recovered successfully $0.0 on TOM(2) -#{@canceled_member.current_membership.terms_of_membership.name}-")
      }
    end
  end
end