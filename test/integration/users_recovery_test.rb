require 'test_helper'

class UsersRecoveryTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent                          = FactoryBot.create(:confirmed_admin_agent)
    @club                                 = FactoryBot.create(:simple_club_with_gateway)
    @partner                              = @club.partner
    Time.zone                             = @club.time_zone
    @terms_of_membership_with_gateway     = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @new_terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'another_tom')
    @member_cancel_reason                 = FactoryBot.create(:member_cancel_reason)
    sign_in_as(@admin_agent)
    active_merchant_stubs_payeezy
  end

  def setup_user(cancel = true)
    unsaved_user = FactoryBot.build(:user_with_api)
    @credit_card = FactoryBot.build(:credit_card)
    @saved_user  = create_user_by_sloop(@admin_agent, unsaved_user, @credit_card, nil, @terms_of_membership_with_gateway)

    if cancel
      cancel_date = Time.zone.now + 1.days
      message = "Member cancellation scheduled to #{cancel_date} - Reason: #{@member_cancel_reason.name}"
      @saved_user.cancel! cancel_date, message, @admin_agent
      @saved_user.set_as_canceled!
      @saved_user.reload
    end
  end

  def recover_user(user, tom, product = nil)
    visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_on 'Recover'

    if @new_terms_of_membership_with_gateway.name != @terms_of_membership_with_gateway.name
      select(@new_terms_of_membership_with_gateway.name, from: 'terms_of_membership_id')
    end

    if product
      select(product.name, from: 'product_sku')
    end
    click_on 'Recover'
    confirm_ok_js
    @saved_user.reload
  end

  def cancel_user(user, date_time)
    visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    click_on 'Cancel'
    page.execute_script("window.jQuery('#cancel_date').next().click()")
    within('#ui-datepicker-div') do
      click_on date_time.day
    end
    select(@member_cancel_reason.name, from: 'reason')
    click_on 'Cancel user'
    confirm_ok_js
    user.set_as_canceled!
  end

  def validate_user_recovery(user, tom)
    visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('#td_mi_status') do
      assert page.has_content?('provisional') if user.status == 'provisional'
    end
    within('#td_mi_join_date') do
      assert page.has_content?(I18n.l(Time.zone.now, format: :only_date))
    end

    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') do
      assert page.has_content?("Member recovered successfully $0.0 on TOM(#{@new_terms_of_membership_with_gateway.id}) -#{@new_terms_of_membership_with_gateway.name}-")
    end

    within('.nav-tabs') { click_on('Memberships') }
    within('#memberships_table') do
      assert page.has_content?(user.current_membership.id.to_s)
      assert page.has_content?(I18n.l(Time.zone.now, format: :only_date))
      assert page.has_content?('lapsed')
    end
    within('#memberships_table') { assert page.has_content?('provisional') if user.status == 'provisional' }
  end

  test 'recover an user using CS with a product and with provisional TOM' do
    setup_user
    product = FactoryBot.create(:product_without_recurrent, club_id: @club.id)
    recover_user(@saved_user, @terms_of_membership_with_gateway, product)
    @saved_user.reload
    assert_not_nil @saved_user.fulfillments.where(product_sku: product.sku)
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_user.current_membership.terms_of_membership.name}-"
    validate_user_recovery(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test 'recover an user using free TOM' do
    setup_user
    free_terms_of_membership = FactoryBot.create(:free_terms_of_membership, club_id: @club.id)
    recover_user(@saved_user, free_terms_of_membership)
    @saved_user.reload
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_user.current_membership.terms_of_membership.name}-"
    validate_user_recovery(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test 'recover an user by Monthly and paid membership' do
    setup_user
    @new_terms_of_membership_with_gateway.installment_type = '1.month'
    @new_terms_of_membership_with_gateway.save

    recover_user(@saved_user, @new_terms_of_membership_with_gateway)
    assert find_field('input_first_name').value == @saved_user.first_name
    page.has_content? "Member recovered successfully $0.0 on TOM(2) -#{@saved_user.current_membership.terms_of_membership.name}-"
    validate_user_recovery(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test 'should not let recover when user is blacklisted' do
    setup_user
    @saved_user.update_attribute(:blacklisted, true)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    find(:xpath, "//a[@id='recovery']")['class'].include? 'disabled'
  end

  test 'recover an user with CC blacklisted' do
    setup_user
    @saved_user.active_credit_card.update_attribute(:blacklisted, true)
    assert_equal @saved_user.active_credit_card.blacklisted, true

    create_user(@saved_user, @credit_card, @terms_of_membership_with_gateway.name)
    assert page.has_content? I18n.t('error_messages.credit_card_blacklisted', cs_phone_number: @saved_user.club.cs_phone_number)
    validate_view_user_base(@saved_user, 'lapsed')
  end

  test 'same CC when recovering user (Sloop)' do
    setup_user
    assert_difference('CreditCard.count', 0) do
      create_user(@saved_user, @credit_card, @terms_of_membership_with_gateway.name)
      wait_until { assert find_field('input_first_name').value == @saved_user.first_name }
    end

    within('#td_mi_status') { assert page.has_content?('provisional') }
    within('#table_active_credit_card') do
      assert page.has_content?(@credit_card.number[-4..-1])
      assert page.has_content?(CREDIT_CARD_TOKEN[@credit_card.number])
    end
    validate_view_user_base(@saved_user)
  end

  test 'complimentary users should be recover' do
    @terms_of_membership_with_gateway.provisional_days = 0
    @terms_of_membership_with_gateway.installment_amount = 0.0
    @terms_of_membership_with_gateway.save
    enrollment_info = FactoryBot.build :membership_with_enrollment_info_without_enrollment_amount
    unsaved_user    = FactoryBot.build(:user_with_api)

    assert_difference('User.count') do
      @saved_user = create_user_by_sloop(@admin_agent, unsaved_user, nil, enrollment_info, @terms_of_membership_with_gateway, true, true)
    end
    assert_difference('Transaction.count') { @saved_user.bill_membership }
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#table_membership_information') do
      within('#td_mi_status') { assert page.has_content?('active') }
    end

    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#table_membership_information') do
      within('#td_mi_status') { assert page.has_content?('lapsed') }
    end
    assert_equal @saved_user.status, 'lapsed'

    recover_user(@saved_user, @terms_of_membership_with_gateway)
    validate_user_recovery(@saved_user, @terms_of_membership_with_gateway)
  end
end
