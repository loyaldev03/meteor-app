require 'test_helper'

class MembersBlacklistTest < ActionController::IntegrationTest

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
    @member_blacklist_reason =  FactoryGirl.create(:member_blacklist_reason)
    FactoryGirl.create(:batch_agent)

    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end
    sign_in_as(@admin_agent)
  end

  def create_new_member(unsaved_member, bl_credit_card, bl_email, new_partner, new_club, new_terms_of_membership_with_gateway)
    visit members_path(:partner_prefix => new_partner.prefix, :club_prefix => new_club.name)

    click_on 'New Member'

    within("#table_demographic_information") {
      fill_in 'member[first_name]', :with => unsaved_member.first_name
      fill_in 'member[last_name]', :with => unsaved_member.last_name
      fill_in 'member[city]', :with => unsaved_member.city
      fill_in 'member[address]', :with => unsaved_member.address
      select('M', :from => 'member[gender]')
      fill_in 'member[zip]', :with => unsaved_member.zip
      select_country_and_state(unsaved_member.country)
    }

    page.execute_script("window.jQuery('#member_birth_date').next().click()")
    within(".ui-datepicker-calendar") do
      click_on("1")
    end

    within("#table_contact_information") {
      fill_in 'member[email]', :with => bl_email
      fill_in 'member[phone_country_code]', :with => unsaved_member.phone_country_code
      fill_in 'member[phone_area_code]', :with => unsaved_member.phone_area_code
      fill_in 'member[phone_local_number]', :with => unsaved_member.phone_local_number
      select('Home', :from => 'member[type_of_phone_number]')
      select(new_terms_of_membership_with_gateway.name, :from => 'member[terms_of_membership_id]')
    }

    @number = "4012301230123010"
    @last_digits = @number[-4..4]
    active_merchant_stubs_store(@number)

    within("#table_credit_card") {  
      fill_in 'member[credit_card][number]', :with => @number
      fill_in 'member[credit_card][expire_month]', :with => "#{bl_credit_card.expire_month}"
      fill_in 'member[credit_card][expire_year]', :with => "#{bl_credit_card.expire_year}"
    }
    
    alert_ok_js
    
    click_link_or_button 'Create Member'
    sleep(5) #Wait for API response
  end

  def blacklist_member(member,reason)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.visible_id)
    click_on 'Blacklist'
    select(reason, :from => 'reason')
    confirm_ok_js
    click_on 'Blacklist member'
  end

  def validate_blacklisted_member(member, validate_cancel_date = false)
    member.reload
    text_reason = "Blacklisted member and all its credit cards. Reason: #{@member_blacklist_reason.name}"
    wait_until{
      assert page.has_content?(text_reason)
      assert page.has_content?("Blacklisted!!!")
      assert_equal member.blacklisted, true
    }

    if validate_cancel_date
      within("#td_mi_cancel_date") do
        assert page.has_content?(I18n.l(member.cancel_date, :format => :only_date))
      end
    end

    within("#operations_table") do
      wait_until {
        assert page.has_content?(text_reason)
      }
    end
    
    active_credit_card = member.active_credit_card
    within("#credit_cards") { 
      assert page.has_content?("#{@last_digits}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
      assert page.has_content?("Blacklisted active")
    }
    assert active_credit_card.blacklisted == true
  end


  test "blacklist member with CC" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "blacklist member with more CC" do
    setup_member
    FactoryGirl.create(:credit_card_master_card, :member_id => @saved_member.id)
    @saved_member.reload

    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "create member with blacklist CC" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
    bl_credit_card = @saved_member.active_credit_card

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    create_new_member(unsaved_member, bl_credit_card, unsaved_member.email, @partner, @club, @terms_of_membership_with_gateway)

    wait_until { assert page.has_content?(Settings.error_messages.credit_card_blacklisted) }
    assert Member.count == 1
  end

  test "create member width blacklist email" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
    bl_email = @saved_member.email

    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id, :email => bl_email)
    create_new_member(unsaved_member, unsaved_member.credit_cards.first, bl_email, @partner, @club, @terms_of_membership_with_gateway)

    wait_until { assert page.has_content?(Settings.error_messages.member_email_blacklisted) }
    assert Member.count == 1
  end

  test "create member from another club width blacklist CC" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
    bl_credit_card = @saved_member.active_credit_card

    partner_new = FactoryGirl.create(:partner)
    club_new = FactoryGirl.create(:simple_club_with_gateway, :partner_id => partner_new.id)
    Time.zone = club_new.time_zone
    terms_of_membership_with_gateway_new = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => club_new.id)
    unsaved_member = FactoryGirl.build(:active_member)
    create_new_member(unsaved_member, bl_credit_card, unsaved_member.email, partner_new, club_new, terms_of_membership_with_gateway_new)

    assert page.has_content?("#{unsaved_member.first_name} #{unsaved_member.last_name}")
    assert Member.count == 2
  end

  test "Blacklist a member with status Lapsed" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.reload
    
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member
)  end

  test "Blacklist a member with status Active" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "Blacklist a member with status Provisional" do
    setup_member(false)
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc, nil, {}, { :created_by => @admin_agent })
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "Blacklist a member with status Applied" do
    setup_member(false)
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :applied_member, nil, {}, { :created_by => @admin_agent })
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "Do not allow recover Blacklist member" do
    setup_member
    @saved_member.update_attribute(:blacklisted,true)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until { assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']") }
    wait_until { assert find(:xpath, "//a[@id='blacklist_btn' and @disabled='disabled']") }
  end

end