require 'test_helper'

class UsersBillTest < ActionDispatch::IntegrationTest
  setup do
    active_merchant_stubs_payeezy('100', 'Transaction Normal - Approved with Stub', true)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
  end

  def setup_user(provisional_days = nil, create_user = true, club_with_gateway = :simple_club_with_gateway)
    @club                             = FactoryBot.create(club_with_gateway)
    @partner                          = @club.partner
    Time.zone                         = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_gateway.provisional_days = provisional_days unless provisional_days.nil?
    @communication_type = FactoryBot.create(:communication_type)
    @disposition_type = FactoryBot.create(:disposition_type, club_id: @club.id)

    sign_in_as(@admin_agent)

    if create_user
      unsaved_user        = FactoryBot.build(:user_with_cc, club_id: @club.id)
      enrollment_info     = FactoryBot.build(:membership_with_enrollment_info, enrollment_amount: 0.0)
      credit_card_to_load = FactoryBot.build(:credit_card)
      @saved_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card_to_load, enrollment_info, @terms_of_membership_with_gateway)
      visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    end
  end

  def make_a_refund(transaction, amount = nil, check_refund = true)
    amount ||= transaction.amount_available_to_refund

    visit user_refund_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, transaction_id: transaction.id)
    fill_in 'refund_amount', with: amount.to_s

    alert_ok_js
    click_on 'Refund'
    if check_refund
      page.has_content?('This transaction has been approved')

      within('.nav-tabs') { click_on('Operations') }
      within('#operations_table') do
        assert page.has_content?("Communication 'Test refund' sent")
        assert page.has_content?("Refund success $#{amount.to_f}")
        assert page.has_content?(I18n.l(Time.zone.now.in_time_zone(@saved_user.get_club_timezone), format: :only_date))
      end
      within('.nav-tabs') { click_on 'Transactions' }
      within('#transactions_table') do
        assert page.has_content?('Credit : Transaction Normal - Approved with Stub') || page.has_content?('Billing: Refund - Transaction Normal - Approved with Stub') || page.has_content?('Credit : This transaction has been approved with stub')
        assert page.has_content?(amount)
      end
      within('.nav-tabs') { click_on 'Communications' }
      within('#communications') do
        assert page.has_content?('Test refund')
        assert page.has_content?('refund')
      end
    end
  end

  def make_a_chargeback(transaction, date, amount, reason, check_chargeback = true)
    visit user_chargeback_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, transaction_id: transaction.id)

    page.execute_script("window.jQuery('#adjudication_date').next().click()")
    within('#ui-datepicker-div') do
      if date.month != Time.zone.now.month
        within('.ui-datepicker-header') do
          find('.ui-icon-circle-triangle-e').click
        end
      end
      first(:link, date.day.to_s).click if first(:link, date.day.to_s)
    end
    fill_in 'amount', with: amount.to_s
    fill_in 'reason', with: reason

    alert_ok_js
    click_on 'Chargeback'
    if check_chargeback
      page.has_content?('User successfully chargebacked.')
      chargeback_transaction = Transaction.where(transaction_type: 'chargeback').last
      @saved_user.reload

      assert_equal chargeback_transaction.amount, -amount
      assert_equal chargeback_transaction.response['transaction_amount'].to_f, amount.to_f
      assert_equal chargeback_transaction.response['reason'], reason
      assert_equal chargeback_transaction.response['sale_transaction_id'], transaction.id
      assert_equal chargeback_transaction.operation_type, Settings.operation_types.chargeback
      assert_equal @saved_user.status, 'lapsed'
      assert_equal @saved_user.blacklisted, true
    end
  end

  def change_next_bill_date(date, error_message = ' ')
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    click_link_or_button 'Change'
    page.has_content?(I18n.t('activerecord.attributes.user.next_retry_bill_date'))
    unless date.nil?
      page.execute_script("window.jQuery('#next_bill_date').next().click()")
      within('#ui-datepicker-div') do
        unless page.has_content? date.strftime('%B')
          within('.ui-datepicker-header') do
            find('.ui-icon-circle-triangle-e').click
          end
        end
        first(:link, date.day.to_s).click if first(:link, date.day.to_s)
      end
    end
    click_link_or_button 'Change next bill date'
  rescue Exception => e
    puts "Timezone: #{Time.zone}, date: #{next_bill_date}, error_message: #{error_message}"
  end

  test "See HD for 'Soft recycle limit'" do
    setup_user
    @saved_user.current_membership.update_attribute(:enrollment_amount, 0.0)
    @sd_strategy = FactoryBot.create(:soft_decline_strategy)
    @hd_strategy = FactoryBot.create(:hard_decline_strategy)
    active_merchant_stubs_payeezy(@sd_strategy.response_code, 'decline stubbed', false)

    within('#table_membership_information') do
      within('#td_mi_recycled_times') do
        assert page.has_content? '0'
      end
      within('#td_mi_status') do
        assert page.has_content?('provisional')
      end
    end
    recycle_time = 0
    2.upto(5) do |_time|
      @saved_user.update_attribute(:next_retry_bill_date, Time.zone.now)
      @saved_user.bill_membership
      recycle_time += 1
      @saved_user.reload
      visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)

      if @saved_user.next_retry_bill_date.nil?
        within('#table_membership_information') do
          within('#td_mi_recycled_times') do
            assert page.has_content? '0'
          end
          within('#td_mi_status') do
            assert page.has_content?('lapsed')
          end
        end
      else
        within('#table_membership_information') do
          within('#td_mi_recycled_times') do
            assert page.has_content?(recycle_time.to_s)
          end
          within('#td_mi_status') do
            assert page.has_content?('provisional')
          end
        end
      end
    end
  end

  test 'create an user billing enroll > 0 and refund enrollment transaction' do
    setup_user
    sale_transaction = bill_user(@saved_user)
    make_a_refund(sale_transaction)
  end

  # Change user from Lapsed status to Provisional status
  test 'Change user from Provisional (trial) or active status to Lapsed (inactive) status' do
    setup_user
    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('#td_mi_next_retry_bill_date') do
      assert page.has_no_content?(I18n.l(Time.zone.now.in_time_zone(@saved_user.get_club_timezone), format: :only_date))
    end
    @saved_user.recover(@terms_of_membership_with_gateway)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    next_bill_date = @saved_user.current_membership.join_date + @terms_of_membership_with_gateway.provisional_days

    within('#td_mi_next_retry_bill_date') do
      assert page.has_no_content?(I18n.l(next_bill_date, format: :only_date))
    end
    @saved_user.set_as_active!
    @saved_user.set_as_canceled
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('#td_mi_next_retry_bill_date') do
      assert page.has_no_content?(I18n.l(Time.zone.now.in_time_zone(@saved_user.get_club_timezone), format: :only_date))
    end
  end

  test 'Change Next Bill Date for tomorrow' do
    setup_user
    @saved_user.set_as_canceled
    @saved_user.recover(@terms_of_membership_with_gateway)
    @saved_user.set_as_active
    next_bill_date = Time.zone.now.utc + 1.day

    change_next_bill_date(next_bill_date, 'Change Next Bill Date for tomorrow')
    while find_field('input_first_name').value != @saved_user.first_name
      next_bill_date += 1.hour
      change_next_bill_date(next_bill_date, 'Change Next Bill Date for tomorrow')
    end
    within('#td_mi_next_retry_bill_date') do
      assert page.has_content?(I18n.l(next_bill_date, format: :only_date)), "Timezone: #{Time.zone}, date searched: #{next_bill_date}, user's date: #{@saved_user.next_retry_bill_date}"
    end
  end

  test 'Next Bill Date for monthly memberships' do
    setup_user
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    first_bill_date = @saved_user.join_date + @terms_of_membership_with_gateway.provisional_days.days

    within('#td_mi_next_retry_bill_date') do
      assert page.has_content?(I18n.l(first_bill_date, format: :only_date))
    end

    bill_user(@saved_user)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    second_bill_date = first_bill_date + @terms_of_membership_with_gateway.installment_period.days

    within('#td_mi_next_retry_bill_date') do
      assert page.has_content?(I18n.l(second_bill_date, format: :only_date))
    end
  end

  test 'Refund a transaction with error' do
    setup_user
    @terms_of_membership_with_gateway.update_attribute(:installment_amount, 45.56)
    active_merchant_stubs_payeezy('34234', 'Transaction Declined with Stub', false)
    @saved_user.bill_membership
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') do
      click_on('Transactions')
    end
    within('#transactions_table_wrapper') do
      assert page.has_no_selector?('#refund')
    end
  end

  test 'Provisional user' do
    setup_user
    @saved_user.current_membership.join_date = Time.zone.now - 3.day
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name

    within('#td_mi_status') do
      assert page.has_content?('provisional')
    end

    within('.nav-tabs') { click_on('Operations') }
    within('#operations_table') do
      assert page.has_content?("Member enrolled successfully $0.0 on TOM(#{@terms_of_membership_with_gateway.id}) -#{@terms_of_membership_with_gateway.name}-")
    end
  end

  test 'Refund from CS' do
    setup_user
    @saved_user.current_membership.join_date = Time.zone.now - 3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2)
    bill_user(@saved_user)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table_wrapper') { assert page.has_selector?('#refund') }

    assert_difference('Transaction.count', 0) do
      make_a_refund(Transaction.last, '&%$', false)
    end
    assert_difference('Transaction.count') do
      make_a_refund(@saved_user.transactions.where('operation_type = 101').order('created_at ASC').first, final_amount)
    end
    assert_difference('Transaction.count', 0) do
      make_a_refund(@saved_user.transactions.where('operation_type = 101').order('created_at ASC').first, final_amount + 1, false)
      assert page.has_content?('Cant credit more $ than the original transaction amount')
    end
  end

  test 'Partial refund from CS' do
    setup_user
    @saved_user.current_membership.join_date = Time.zone.now - 3.day
    final_amount = (@terms_of_membership_with_gateway.installment_amount / 2)
    bill_user(@saved_user)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table_wrapper') do
      assert page.has_selector?('#refund')
    end
    make_a_refund(Transaction.last, final_amount)
  end

  test 'Billing membership amount on the Next Bill Date' do
    setup_user
    @saved_user.current_membership.join_date + @terms_of_membership_with_gateway.provisional_days.days
    @saved_user.next_retry_bill_date + @terms_of_membership_with_gateway.installment_period.days

    excecute_like_server(@club.time_zone) do
      bill_user(@saved_user)
    end

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id)
    within('#table_membership_information') do
      within('#td_mi_club_cash_amount') { assert page.has_content?((@terms_of_membership_with_gateway.club_cash_installment_amount.to_i + @terms_of_membership_with_gateway.initial_club_cash_amount.to_i).to_s) }
    end

    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') do
      assert page.has_content?('Sale : Transaction Normal - Approved with Stub')
      assert page.has_content?(@terms_of_membership_with_gateway.installment_amount.to_s)
    end
  end

  test 'Representative and Supervisor should be able to refund' do
    setup_user
    %w[representative supervisor].each do |role|
      @admin_agent.update_attribute(:roles, role)
      excecute_like_server(@club.time_zone) do
        sale_transaction = bill_user(@saved_user)
        make_a_refund(sale_transaction)
      end
    end
  end

  test 'Hard decline for user without CC information when the billing date arrives' do
    setup_user(nil, false)
    @hd_strategy = FactoryBot.create(:hard_decline_strategy_for_billing)

    active_merchant_stubs_payeezy(@hd_strategy.response_code, 'decline stubbed', false, '0000000000')

    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)
    @saved_user = create_user(unsaved_user, nil, @terms_of_membership_with_gateway.name, true)

    within('#table_active_credit_card') do
      assert page.has_content?('0000 (unknown)')
    end

    @saved_user.update_attribute(:next_retry_bill_date, Time.zone.now)

    excecute_like_server(@club.time_zone) do
      excecute_like_server(@club.time_zone) do
        TasksHelpers.bill_all_members_up_today
      end
    end

    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { assert page.has_content?("Communication 'Test hard_decline' sent") }
    within('#operations') { assert page.has_content?("Communication 'Test cancellation' sent") }
    within('#operations') { assert page.has_content?('Member canceled') }
    within('.nav-tabs') { click_on 'Communications' }
    within('#communications') { assert page.has_content?('hard_decline') }
    within('#communications') { assert page.has_content?('cancellation') }
  end

  test 'Try billing an user with credit card ok, and within a club that allows billing.' do
    setup_user
    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    fill_in('amount', with: '100')
    fill_in('description', with: 'asd')
    click_link_or_button I18n.t('buttons.no_recurrent_billing')

    trans = Transaction.last
    assert page.has_content? "Member billed successfully $100 Transaction id: #{trans.id}. Reason: asd"

    within('.nav-tabs') { click_on 'Operations' }
    within('#operations') { assert page.has_content? "Member billed successfully $100 Transaction id: #{trans.id}. Reason: asd" }
    within('.nav-tabs') { click_on 'Transactions' }
    within('#transactions_table') do
      assert page.has_content?('Sale : Transaction Normal - Approved with Stub.')
      assert page.has_content?('100')
      assert page.has_selector?('#refund')
    end
  end

  test 'Try billing an user providing invalid billing information. (no amount, no description, negative amounts).' do
    setup_user
    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))

    assert_difference('Transaction.count', 0) do
      click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    end
    assert_equal current_path, user_no_recurrent_billing_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)

    fill_in('amount', with: '100')
    assert_difference('Transaction.count', 0) do
      click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    end
    assert_equal current_path, user_no_recurrent_billing_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)

    fill_in('amount', with: '')
    fill_in('description', with: 'asd')
    assert_difference('Transaction.count', 0) do
      click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    end
    assert_equal current_path, user_no_recurrent_billing_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    fill_in('amount', with: '-100')
    fill_in('description', with: 'asd')
    assert_difference('Transaction.count', 0) do
      click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    end
    assert_equal current_path, user_no_recurrent_billing_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
  end

  test 'Try billing an user within a club that do not allow billing.' do
    setup_user
    @saved_user.club.update_attribute(:billing_enable, false)
    visit show_user_path(partner_prefix: @saved_user.club.partner.prefix, club_prefix: @saved_user.club.name, user_prefix: @saved_user.id)
    assert find(:xpath, "//a[@id='no_recurrent_bill_btn']")[:class].include? 'disabled'
    assert page.has_selector?('#blacklist_btn')
  end

  test 'Try billing an user with blank credit card.' do
    setup_user(nil, false)
    unsaved_user = FactoryBot.build(:user_with_cc, club_id: @club.id)
    @saved_user = create_user(unsaved_user, nil, nil, true)
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    fill_in('amount', with: '100')
    fill_in('description', with: 'asd')
    click_link_or_button(I18n.t('buttons.no_recurrent_billing'))
    assert page.has_content?('Credit card is blank we wont bill')
  end
  ################################################
  ## TRUST COMMERCE
  ################################################

  test 'Refund from CS a transaction from TRUST COMMERCE' do
    active_merchant_stubs_trust_commerce
    setup_user(nil, true, :simple_club_with_trust_commerce_gateway)
    bill_user(@saved_user)
    transaction = @saved_user.transactions.last
    within('.nav-tabs') { click_on('Transactions') }
    within('#transactions_table_wrapper') { assert page.has_selector?('#refund') }
    make_a_refund(transaction, transaction.amount)
  end

  test 'Chargeback user via web' do
    active_merchant_stubs_trust_commerce
    setup_user(nil, true, :simple_club_with_trust_commerce_gateway)
    bill_user(@saved_user)
    transaction = @saved_user.transactions.last
    assert_difference('Transaction.count', 0) do
      make_a_chargeback(transaction, transaction.created_at, 'asd', 'I have my reasons...', false)
    end
    assert_difference('Transaction.count', 0) do
      make_a_chargeback(transaction, transaction.created_at, transaction.amount + 100, 'I have my reasons...', false)
      assert page.has_content? I18n.t('error_messages.chargeback_amount_greater_than_available')
    end
    assert_difference('Transaction.count') do
      make_a_chargeback(transaction, transaction.created_at, transaction.amount, 'I have my reasons...')
    end
  end
end
