require 'test_helper'

class TermsOfMembershipsTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
  end

  def fill_in_form(options = {}, options_for_select = {}, options_for_check = [])
    options_for_check.each do |value|
      choose(value)
    end

    options_for_select.each do |field, value|
      select(value, from: field)
    end

    options.each do |field, value|
      fill_in field, with: value unless %i[initial_fee_amount trial_period_amount].include? field
    end
  end

  def fill_in_step_1(name = nil, external_code = nil, description = nil)
    find('.step_selected', text: '1')
    fill_in 'terms_of_membership[name]', with: name if name
    select_into_dropdown('#terms_of_membership_api_role', '6 - Paid User')
    fill_in 'terms_of_membership[description]', with: description if description
  end

  def fill_in_step_2(options = {}, options_for_select = [], options_for_check = {})
    find('.step_selected', text: '2')
    fill_in_form(options, options_for_select, options_for_check)
  end

  test 'Create subcription plan with Free Trial Period in Days' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Trial Period in Days'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2(initial_fee_amount: 0, trial_period_amount: 0, trial_period_lasting: 30, installment_amount: 0, installment_amount_days: 1)
    click_link_or_button 'Define Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
  end

  test 'Create subcription plan with Recurring Amount in Months' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM with Recurring Amount in Months'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2({ initial_fee_amount: 0, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 10, installment_amount_days: 1 }, installment_amount_days_time_span: 'Month(s)')
    click_link_or_button 'Define Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test "Create a TOM with 'no payment is expected' selected - with Trial Period and Initial Club cash" do
    sign_in_as(@admin_agent)
    tom_name = 'TOM with No payment expected'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2({ initial_fee_amount: 0, trial_period_amount: 1, trial_period_lasting: 1, terms_of_membership_initial_club_cash_amount: 20 }, {}, ['is_payment_expected_no'])
    assert page.has_content? I18n.t('activerecord.attributes.terms_of_membership.wizard.keep_active_until_manually_cancelled')

    click_link_or_button 'Define Upgrades / Downgrades'
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

    @terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user = FactoryBot.build(:active_user, club_id: @terms_of_membership.club_id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    saved_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)

    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: saved_user.id)
    within('#table_membership_information') do
      within('#td_mi_club_cash_amount') { assert page.has_content?(@terms_of_membership.initial_club_cash_amount) }
      assert page.has_content? I18n.t('activerecord.attributes.user.billing_is_not_expected')
    end
    assert_nil saved_user.next_retry_bill_date
  end

  test 'Create an user at TOM created by Subscription Plan' do
    sign_in_as(@admin_agent)
    # First, create the TOM
    tom_name = 'TOM To Create the User'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2(initial_fee_amount: 1, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 0, installment_amount_days: 1)
    click_link_or_button 'Define Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
    # Then, create the user
    the_tom = TermsOfMembership.last
    the_user = create_active_user(the_tom, :active_user, nil, {}, created_by: @admin_agent)
    visit show_user_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: the_user.id)
    assert page.find('#table_membership_information').has_content?(tom_name) # TOM is in the table
  end

  test 'Create subcription plan with Downgrade to option' do
    sign_in_as(@admin_agent)
    tom_to_downgrade = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    tom_name = 'TOM with Downgrade To'
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2({ initial_fee_amount: 1, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 10, installment_amount_days: 1 }, installment_amount_days_time_span: 'Month(s)')
    click_link_or_button 'Define Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_downgrade_to')
    select(tom_to_downgrade.name, from: 'downgrade_to_tom')
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Create a new TOM with club cash and enroll an user with it' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name with club cash'
    initial_amount_of_club_cash = 80
    club_cash_installment_amount = 100
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    click_link_or_button 'Add New Plan'

    fill_in_step_1(tom_name)
    click_link_or_button 'Define Membership Terms'
    fill_in_step_2(initial_fee_amount: 1, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 0, installment_amount_days: 1, terms_of_membership_initial_club_cash_amount: initial_amount_of_club_cash, terms_of_membership_club_cash_installment_amount: club_cash_installment_amount)
    click_link_or_button 'Define Upgrades / Downgrades'

    find_button('Create Plan')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Create Plan'
    assert page.has_content?('was created succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table

    @terms_of_membership = TermsOfMembership.find_by_name tom_name
    unsaved_user = FactoryBot.build(:active_user, club_id: @terms_of_membership.club_id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    @saved_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)
    visit show_user_path(partner_prefix: @terms_of_membership.club.partner.prefix, club_prefix: @terms_of_membership.club.name, user_prefix: @saved_user.id)
    within('#td_mi_club_cash_amount') { assert page.has_content?(initial_amount_of_club_cash) }
  end

  test 'Create an user with TOM upgrate to = 1' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name with upgrade'
    tom_to_upgrade = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'Upgraded TOM')

    assert_difference('TermsOfMembership.count', 1) do
      @terms_of_membership = FactoryBot.create(:terms_of_membership, initial_fee: 1,
                                 name: tom_name, description: ' ', club_id: tom_to_upgrade.club_id,
                                 provisional_days: 0, subscription_limits: 0, initial_club_cash_amount: 0,
                                 installment_amount: 0, installment_period: 1, upgrade_tom_period: 1,
                                 is_payment_expected: true, needs_enrollment_approval: false,
                                 upgrade_tom_id: tom_to_upgrade.id, club_cash_installment_amount: 0,
                                 skip_first_club_cash: false)
    end

    unsaved_user = FactoryBot.build(:active_user, club_id: @terms_of_membership.club_id)
    credit_card = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    @saved_user = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, @terms_of_membership)
    visit show_user_path(partner_prefix: @terms_of_membership.club.partner.prefix, club_prefix: @terms_of_membership.club.name, user_prefix: @saved_user.id)
  end

  test 'Update subcription plan with Free Trial Period by months - No membership associated' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end
    fill_in_step_1(tom_name + ' Updated')
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2({ initial_fee_amount: 10, trial_period_amount: 0, trial_period_lasting: 10, installment_amount: 10, installment_amount_days: 1 }, { trial_period_lasting_time_span: 'Month(s)' }, %w[is_payment_expected_yes subscription_terms_until_cancelled])
    click_link_or_button 'Edit Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Update subcription plan with Paid Trial Period by days - No membership associated' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1(tom_name + ' Updated')
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2({ initial_fee_amount: 10, trial_period_amount: 20, trial_period_lasting: 10, installment_amount: 10, installment_amount_days: 1 }, { trial_period_lasting_time_span: 'Day(s)' }, %w[is_payment_expected_yes subscription_terms_until_cancelled])
    click_link_or_button 'Edit Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Update subcription plan with Recurring Amount by month - No membership associated' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1(tom_name + ' Updated')
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2({ initial_fee_amount: 10, trial_period_amount: 20, trial_period_lasting: 10, installment_amount: 10, installment_amount_days: 6 }, { trial_period_lasting_time_span: 'Month(s)', installment_amount_days_time_span: 'Month(s)' }, %w[is_payment_expected_yes subscription_terms_until_cancelled])
    click_link_or_button 'Edit Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Update subcription plan with No payment is expected - No membership associated' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1(tom_name + ' Updated')
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2({ initial_fee_amount: 10, trial_period_amount: 20, trial_period_lasting: 30 }, { trial_period_lasting_time_span: 'Month(s)' }, %w[is_payment_expected_no subscription_terms_until_cancelled])
    click_link_or_button 'Edit Upgrades / Downgrades'
    assert page.has_content? 'According to the configuration you selected on step 2, there is nothing to configure on this step.'
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Update subcription plan with external code and description - No membership associated' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1(tom_name + ' Updated', 'API Role Updated', 'Description Updated')
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2({ initial_fee_amount: 10, trial_period_amount: 20, trial_period_lasting: 30,
              installment_amount: 10, installment_amount_days: 24 },
                   { installment_amount_days_time_span: 'Month(s)' },
             %w[is_payment_expected_yes subscription_terms_until_cancelled])
    click_link_or_button 'Edit Upgrades / Downgrades'

    find('label', text: 'If we cannot bill an user then')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was created
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
  end

  test 'Do not edit TOM with active (active, applied and provisional) membership' do
    sign_in_as(@admin_agent)
    27.times { |n| FactoryBot.create(:terms_of_membership_with_gateway, name: "test#{n}", club_id: @club.id) }
    the_tom = TermsOfMembership.last
    create_active_user(the_tom, :active_user, nil, {}, created_by: @admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: the_tom.name) do
        click_link_or_button 'Edit'
        confirm_ok_js
      end
    end
    assert page.has_content?('can not be edited')
  end

  test 'Do not edit TOM with inactive (lapsed) membership' do
    sign_in_as(@admin_agent)
    27.times { |n| FactoryBot.create(:terms_of_membership_with_gateway, name: "test#{n}", club_id: @club.id) }
    the_tom = TermsOfMembership.last
    create_active_user(the_tom, :lapsed_user, nil, {}, created_by: @admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: the_tom.name) do
        click_link_or_button 'Edit'
        confirm_ok_js
      end
    end
    assert page.has_content?('can not be edited')
  end

  test 'Delete club cash at TOM - TOM without users' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2(initial_fee_amount: 1, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 0, installment_amount_days: 1, terms_of_membership_initial_club_cash_amount: 0, terms_of_membership_club_cash_installment_amount: 0)
    click_link_or_button 'Edit Upgrades / Downgrades'

    find_button('Update Plan')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was updated
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
    tom.reload
    assert_equal tom.initial_club_cash_amount.to_i, 0
    assert_equal tom.club_cash_installment_amount.to_i, 0
  end

  test 'Edit TOM without users and add club cash' do
    sign_in_as(@admin_agent)
    tom_name = 'TOM Name'
    initial_club_cash_amount = 50
    club_cash_installment_amount = 150
    tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: tom_name)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: tom_name) do
        click_link_or_button 'Edit'
      end
    end

    fill_in_step_1
    click_link_or_button 'Edit Membership Terms'
    fill_in_step_2(initial_fee_amount: 1, trial_period_amount: 0, trial_period_lasting: 0, installment_amount: 0, installment_amount_days: 1, terms_of_membership_initial_club_cash_amount: initial_club_cash_amount, terms_of_membership_club_cash_installment_amount: club_cash_installment_amount)
    click_link_or_button 'Edit Upgrades / Downgrades'

    find_button('Update Plan')
    choose('if_cannot_bill_user_cancel')
    click_link_or_button 'Update Plan'
    assert page.has_content?('was updated succesfully') # TOM was updated
    assert page.find('#terms_of_memberships_table').has_content?(tom_name) # TOM is in the table
    tom.reload
    assert_equal tom.initial_club_cash_amount.to_i, initial_club_cash_amount.to_i
    assert_equal tom.club_cash_installment_amount.to_i, club_cash_installment_amount.to_i
  end

  test 'Delete unused TOM' do
    sign_in_as(@admin_agent)
    27.times { |n| FactoryBot.create(:terms_of_membership_with_gateway, name: "test#{n}", club_id: @club.id) }
    the_tom = TermsOfMembership.last
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: the_tom.name) do
        click_link_or_button 'Destroy'
        confirm_ok_js
      end
    end
    assert page.has_content?('was successfully destroyed.')
  end

  test 'Do not delete a TOM with inactive memberships' do
    sign_in_as(@admin_agent)
    27.times { |n| FactoryBot.create(:terms_of_membership_with_gateway, name: "test#{n}", club_id: @club.id) }
    the_tom = TermsOfMembership.last
    create_active_user(the_tom, :lapsed_user, nil, {}, created_by: @admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: the_tom.name) do
        click_link_or_button 'Destroy'
        confirm_ok_js
      end
    end
    assert page.has_content?("Subscription Plan #{the_tom.name} (ID: #{the_tom.id}) was not destroyed: There are users enrolled related to this Subscription Plan")
  end

  test 'Do not delete a TOM with active memberships' do
    sign_in_as(@admin_agent)
    27.times { |n| FactoryBot.create(:terms_of_membership_with_gateway, name: "test#{n}", club_id: @club.id) }
    the_tom = TermsOfMembership.last
    create_active_user(the_tom, :active_user, nil, {}, created_by: @admin_agent)
    visit terms_of_memberships_path(@partner.prefix, @club.name)
    within('#terms_of_memberships_table') do
      find('.sorting_asc', text: 'ID').click # Sorting desc to show the last tom we had created as the first row of the table
      within('tr', text: the_tom.name) do
        click_link_or_button 'Destroy'
        confirm_ok_js
      end
    end
    assert page.has_content?("Subscription Plan #{the_tom.name} (ID: #{the_tom.id}) was not destroyed: There are users enrolled related to this Subscription Plan")
  end
end
