require 'test_helper'

class MembersBlacklistTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
  end

  def setup_member(create_new_member = true)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @member_blacklist_reason =  FactoryGirl.create(:member_blacklist_reason)

    if create_new_member
      @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    end
    sign_in_as(@admin_agent)
  end

  def blacklist_member(member,reason)
    visit show_member_path(:partner_prefix => member.club.partner.prefix, :club_prefix => member.club.name, :member_prefix => member.id)
    click_on 'Blacklist'
    select(reason, :from => 'reason')
    confirm_ok_js
    click_on 'Blacklist member'
  end

  def validate_blacklisted_member(member, validate_cancel_date = false)
    member.reload
    text_reason = "Blacklisted member and all its credit cards. Reason: #{@member_blacklist_reason.name}"
    assert page.has_content?(text_reason)
    assert page.has_content?("Blacklisted!!!")
    assert_equal member.blacklisted, true

    if validate_cancel_date
      within("#td_mi_cancel_date") do
        assert page.has_content?(I18n.l(member.cancel_date, :format => :only_date))
      end
    end

    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table"){ assert page.has_content?(text_reason) }
    
    active_credit_card = member.active_credit_card
      within('.nav-tabs'){click_on 'Credit Cards'}
        within("#credit_cards") do 
          assert page.has_content?("#{@last_digits}") 
          assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
          assert page.has_content?("Blacklisted active")
        end
      assert active_credit_card.blacklisted == true
  end

  ###########################################################
  # TESTS
  ###########################################################

  test "blacklist member with CC" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "blacklist member with CC and then reactivate a new member with the prev cc blacklisted" do
    setup_member
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)

    blacklisted_credit_card_number = "4012301230123010"

    unsaved_member =  FactoryGirl.build(:active_member, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:enrollment_info)
    credit_card = FactoryGirl.build(:credit_card_master_card)
    active_merchant_stubs_store(credit_card.number)    
    @saved_member = create_member(unsaved_member,credit_card,@terms_of_membership_with_gateway.name,false)
    @saved_member.reload
    @saved_member.set_as_canceled!

    credit_card = FactoryGirl.build(:credit_card_master_card)
    credit_card.number = blacklisted_credit_card_number
    active_merchant_stubs_store(credit_card.number)    

    assert_difference('Member.count', 0) do 
      create_member_by_sloop(@admin_agent, unsaved_member, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    end
    @saved_member.reload
    
    visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name

    within("#td_mi_status") do
      assert page.has_content?('lapsed')
    end
    within("#td_mi_reactivation_times") do
      assert page.has_content?("0")
    end
  end

  test "blacklist member with more CC" do
    setup_member
    FactoryGirl.create(:credit_card_master_card, :member_id => @saved_member.id)
    @saved_member.reload

    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

  test "create member with blacklist CC" do
    setup_member(false)
    credit_card = FactoryGirl.create(:credit_card_master_card)
    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
    
    bl_credit_card = FactoryGirl.build(:credit_card)
    @saved_member = create_member(unsaved_member, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)

    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
    @saved_member2 = fill_in_member(unsaved_member, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    assert page.has_content?(I18n.t('error_messages.credit_card_blacklisted', :cs_phone_number => @club.cs_phone_number))
    assert Member.count == 1
  end

  test "create member with blacklist email" do
    setup_member(false)
    credit_card = FactoryGirl.create(:credit_card_master_card)
    unsaved_member = FactoryGirl.build(:active_member, :club_id => @club.id)
    
    bl_credit_card = FactoryGirl.build(:credit_card)
    @saved_member = create_member(unsaved_member, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)

    unsaved_member2 = FactoryGirl.build(:active_member, :club_id => @club.id, :email => unsaved_member.email)
    @saved_member2 = fill_in_member(unsaved_member2, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    assert page.has_content?(I18n.t('error_messages.member_email_blacklisted', :cs_phone_number => @club.cs_phone_number))
    assert Member.count == 1
  end

  #TO REVIEW
  test "create member from another club with blacklist CC" do
    setup_member(false)
    @club2 = FactoryGirl.create(:simple_club_with_litle_gateway)
    @partner2 = @club2.partner
    @terms_of_membership_with_gateway2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club2.id)
    credit_card = FactoryGirl.create(:credit_card_master_card)
    unsaved_member = FactoryGirl.build(:member_with_cc, :club_id => @club.id)
    
    bl_credit_card = FactoryGirl.build(:credit_card)
    @saved_member = create_member(unsaved_member, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)

    unsaved_member2 = FactoryGirl.build(:member_with_cc, :club_id => @club2.id)
    @saved_member2 = fill_in_member(unsaved_member2, bl_credit_card, @terms_of_membership_with_gateway2.name, false)
  end

  test "Blacklist a member with status Lapsed" do
    setup_member
    @saved_member.set_as_canceled
    @saved_member.reload
    
    blacklist_member(@saved_member,@member_blacklist_reason.name)
    validate_blacklisted_member(@saved_member)
  end

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

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find(:xpath, "//a[@id='recovery' and @disabled='disabled']")
    assert find(:xpath, "//a[@id='blacklist_btn' and @disabled='disabled']")
  end
end