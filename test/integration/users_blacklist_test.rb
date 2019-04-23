require 'test_helper'

class UsersBlacklistTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @club                             = FactoryBot.create(:simple_club_with_gateway)
    @partner                          = @club.partner
    Time.zone                         = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @member_blacklist_reason          = FactoryBot.create(:member_blacklist_reason)
    sign_in_as(@admin_agent)
  end

  def blacklist_user(user, reason)
    visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
    click_on 'Blacklist'
    select(reason, from: 'reason')
    click_on 'Blacklist user'
    confirm_ok_js
  end

  def validate_blacklisted_user(user, validate_cancel_date = false)
    active_credit_card  = user.reload.active_credit_card
    text_reason         = "Blacklisted member and all its credit cards. Reason: #{@member_blacklist_reason.name}"
    assert page.has_content?(text_reason)
    assert page.has_content?('Blacklisted')
    assert_equal user.blacklisted, true

    if validate_cancel_date
      within('#td_mi_cancel_date') do
        assert page.has_content?(I18n.l(user.cancel_date, format: :only_date))
      end
    end

    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') { assert page.has_content?(text_reason) }
    within('.nav-tabs') { click_on 'Credit Cards' }
    within('#credit_cards') do
      assert page.has_content?(@last_digits)
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
      assert page.has_content?('Blacklisted active')
    end
    assert active_credit_card.blacklisted == true
  end

  test 'blacklist user with CC' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
  end

  test 'blacklist user with CC and then reactivate a new user with the prev cc blacklisted' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)

    blacklisted_credit_card_number = '4000060001234562'

    unsaved_user    = FactoryBot.build(:active_user, club_id: @club.id)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    credit_card     = FactoryBot.build(:credit_card_master_card)
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)
    @saved_user = create_user(unsaved_user, credit_card, @terms_of_membership_with_gateway.name, false)
    @saved_user.reload
    @saved_user.set_as_canceled!

    credit_card = FactoryBot.build(:credit_card_master_card)
    credit_card.number = blacklisted_credit_card_number
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true, credit_card.number)

    assert_difference('User.count', 0) do
      create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership_with_gateway)
    end
    @saved_user.reload

    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('#td_mi_status') do
      assert page.has_content?('lapsed')
    end
  end

  test 'blacklist user with more CC' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    FactoryBot.create(:credit_card_master_card, user_id: @saved_user.id)
    @saved_user.reload

    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
  end

  test 'create user with blacklist CC' do
    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)

    bl_credit_card = FactoryBot.build(:credit_card)
    @saved_user = create_user(unsaved_user, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)
    @saved_user2 = fill_in_user(unsaved_user, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    assert page.has_content?(I18n.t('error_messages.credit_card_blacklisted', cs_phone_number: @club.cs_phone_number))
    assert User.count == 1
  end

  test 'create user with blacklist email' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    FactoryBot.create(:credit_card_master_card)
    unsaved_user = FactoryBot.build(:active_user, club_id: @club.id)

    bl_credit_card = FactoryBot.build(:credit_card)
    @saved_user = create_user(unsaved_user, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)

    assert_difference('User.count', 0) do
      unsaved_user2 = FactoryBot.build(:active_user, club_id: @club.id, email: unsaved_user.email)
      @saved_user2  = fill_in_user(unsaved_user2, bl_credit_card, @terms_of_membership_with_gateway.name, false)
      assert page.has_content?(I18n.t('error_messages.user_email_blacklisted', cs_phone_number: @club.cs_phone_number))
    end
  end

  test 'create user from another club with blacklist CC' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    @club2 = FactoryBot.create(:simple_club_with_litle_gateway)
    @partner2 = @club2.partner
    @terms_of_membership_with_gateway2 = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club2.id)
    FactoryBot.create(:credit_card_master_card)
    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)

    bl_credit_card = FactoryBot.build(:credit_card)
    @saved_user = create_user(unsaved_user, bl_credit_card, @terms_of_membership_with_gateway.name, false)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)

    unsaved_user2 = FactoryBot.build(:user_with_cc, club_id: @club2.id)
    @saved_user2 = fill_in_user(unsaved_user2, bl_credit_card, @terms_of_membership_with_gateway2.name, false)
  end

  test 'Blacklist an user with status Lapsed' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    @saved_user.set_as_canceled
    @saved_user.reload
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
  end

  test 'Blacklist an user with status Active' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
  end

  test 'Blacklist an user with status Provisional' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    blacklist_user(@saved_user, @member_blacklist_reason.name)
    validate_blacklisted_user(@saved_user)
  end

  test 'Do not allow recover nor refund a Blacklist user' do
    @saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    @saved_user.update_attribute(:blacklisted, true)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='recovery']")[:class].include? 'disabled'
    assert find(:xpath, "//a[@id='unblacklist_btn']")
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions') { assert_not page.has_selector?('#refund') }
  end
end
