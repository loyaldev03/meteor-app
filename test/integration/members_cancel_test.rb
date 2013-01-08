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
    @terms_of_membership_with_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    @member_cancel_reason =  FactoryGirl.create(:member_cancel_reason)
    FactoryGirl.create(:batch_agent)

    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
		end

    sign_in_as(@admin_agent)
  end

  def fill_in_member_approval(unsaved_member, credit_card)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
    click_link_or_button 'New Member'

    within("#table_demographic_information")do
      wait_until{
        fill_in 'member[first_name]', :with => unsaved_member.first_name
        select(unsaved_member.gender, :from => 'member[gender]')
        fill_in 'member[address]', :with => unsaved_member.address
        select_country_and_state(unsaved_member.country)
        fill_in 'member[city]', :with => unsaved_member.city
        fill_in 'member[last_name]', :with => unsaved_member.last_name
        fill_in 'member[zip]', :with => unsaved_member.zip
      }
    end
    within("#table_contact_information")do
      wait_until{
        fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
        fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
        fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
        select(unsaved_member.type_of_phone_number.capitalize, :from => 'member[type_of_phone_number]')
        fill_in 'member[email]', :with => unsaved_member.email
        select(@terms_of_membership_with_approval.name, :from => 'member[terms_of_membership_id]')
      }
    end
    within("#table_credit_card")do
      wait_until{
        fill_in 'member[credit_card][number]', :with => credit_card.number
        fill_in 'member[credit_card][expire_year]', :with => credit_card.expire_year
        fill_in 'member[credit_card][expire_month]', :with => credit_card.expire_month
      }
    end
    alert_ok_js
    click_link_or_button 'Create Member'
  end

  #Check cancel email - It is send it by CS inmediate after member is lapsed
  test "cancel member" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
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
    
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
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

    wait_until { assert find_field('input_first_name').value == unsaved_member.first_name }
    @saved_member = Member.find_by_email(unsaved_member.email)

    confirm_ok_js
    click_link_or_button 'Reject'

    within("#td_mi_cancel_date")do
      wait_until{ assert page.has_content?(I18n.l(Time.zone.now, :format => :only_date)) }
    end
  end


end